function pointing_jitter()
% pointing_jitter — reaction-wheel imbalance jitter and RMS pointing error.
%
% Bound to: packages/spacecraft/adcs.deal::ReactionWheel
% Annotation: @simulation:<<computes>> wheelJitter
%
% Invoked by `deal simulate pointing_jitter`. A static wheel imbalance drives a
% radial force at the wheel rate; the body responds through the structural mode
% (resonance amplification Q when a wheel harmonic crosses the mode). The RMS
% body pointing error is checked against REQ_SYS_002 (nadir within 0.1 deg).
%
% Declared inputs are model-derived (wheel speed, static imbalance); the moment
% arm, structural mode, body inertia and Q are fixed bus characteristics.
% Reads/writes the v0 JSON envelope.

    MOMENT_ARM_M    = 0.15;   % wheel offset from the body CG
    STRUCT_FREQ_HZ  = 80.0;   % first structural mode
    INERTIA_KGM2    = 0.04;   % body transverse inertia
    RESONANCE_Q     = 20.0;   % amplification at the mode crossing

    raw = jsondecode(fileread('input.json'));
    if isfield(raw, 'inputs'); in = raw.inputs; else; in = raw; end

    wheelRpm  = getv(in, 'wheelSpeed_rpm');
    imbal_gmm = getv(in, 'staticImbalance_gmm');     % g*mm

    omega = wheelRpm * 2 * pi / 60;          % wheel rate, rad/s
    U     = imbal_gmm * 1e-6;                % static imbalance, kg*m

    force  = U * omega^2;                    % radial imbalance force, N
    torque = force * MOMENT_ARM_M;           % disturbance torque, N*m

    wn = 2 * pi * STRUCT_FREQ_HZ;
    thetaPeak = (torque / (INERTIA_KGM2 * wn^2)) * RESONANCE_Q;  % rad
    rmsDeg = rad2deg(thetaPeak / sqrt(2));

    o = struct();
    o.rmsPointing          = mkval(round(rmsDeg, 4), 'deg');
    o.disturbanceTorque_Nm = mkval(round(torque, 5), 'N*m');
    writeOutput(o);
end

function v = getv(in, name)
    f = in.(name);
    if isstruct(f) && isfield(f, 'value'); v = f.value; else; v = f; end
end

function s = mkval(val, unit)
    s = struct('value', val, 'unit', unit);
end

function writeOutput(outputs)
    out = struct('deal_sim_protocol', 'v0', 'v', 1, 'exit_code', 0, ...
                 'outputs', outputs);
    fid = fopen('output.json', 'w');
    fprintf(fid, '%s', jsonencode(out));
    fclose(fid);
end

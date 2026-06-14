function detumble_bdot()
% detumble_bdot — B-dot magnetorquer detumble time from initial tumble.
%
% Bound to: packages/spacecraft/adcs.deal::Magnetorquer
% Annotation: @simulation:<<computes>> detumblePerformance
%
% Invoked by `deal simulate detumble_bdot`. Estimates detumble time (orbits)
% against the "< 2 orbits" budget. Controllable torque is the magnetorquer
% dipole crossed into the geomagnetic field; only the perpendicular component
% is usable (CONTROL_EFFICIENCY).
%
% Declared inputs are model-derived (dipole, spacecraft inertia, orbit period);
% the worst-case initial tumble rate and field strength are mission constants.
% Reads/writes the v0 JSON envelope.

    INITIAL_RATE_DEG_S = 10.0;   % worst-case separation tumble
    FIELD_STRENGTH_T   = 3.0e-5; % representative LEO geomagnetic field
    CONTROL_EFFICIENCY = 0.3;    % usable (perpendicular) fraction of dipole torque
    RESIDUAL_RATE_DEG  = 0.15;   % rate floor near the control deadband

    raw = jsondecode(fileread('input.json'));
    if isfield(raw, 'inputs'); in = raw.inputs; else; in = raw; end

    dipole   = getv(in, 'dipoleMoment_Am2');
    inertia  = getv(in, 'inertia_kgm2');
    period_s = getv(in, 'orbitPeriod_s');

    omega0 = deg2rad(INITIAL_RATE_DEG_S);            % rad/s
    torque = CONTROL_EFFICIENCY * dipole * FIELD_STRENGTH_T;  % N*m
    alpha  = torque / inertia;                       % rad/s^2

    detumble_s     = omega0 / alpha;
    detumbleOrbits = detumble_s / period_s;

    o = struct();
    o.detumbleTime_orbits = mkval(round(detumbleOrbits, 3), 'orbit');
    o.detumbleTime_s      = mkval(round(detumble_s, 1), 's');
    o.finalRate_deg_s     = mkval(RESIDUAL_RATE_DEG, 'deg/s');
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

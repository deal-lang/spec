function eclipse_power()
% eclipse_power — worst-case orbital eclipse fraction and orbit period.
%
% Bound to: model/halcyon.dealx::Halcyon
% Annotation: @simulation:<<computes>> orbitGeometry
%
% Invoked by `deal simulate eclipse_power`. Produces the worst-case eclipse
% fraction (at the input beta angle) and orbit period for the SSO 550 km orbit;
% these are written back to Halcyon.eclipseFraction / Halcyon.orbitPeriod and
% chained into eps_energy_balance.
%
% Declared inputs are model-derived (orbit altitude and sun-beta angle); the
% Earth radius is a fixed constant. Reads/writes the v0 JSON envelope.

    EARTH_RADIUS_KM = 6371.0;
    MU = 398600.4418;                 % Earth GM, km^3/s^2

    raw = jsondecode(fileread('input.json'));
    if isfield(raw, 'inputs'); in = raw.inputs; else; in = raw; end

    h       = getv(in, 'altitude_km');
    betaDeg = getv(in, 'betaAngle_deg');

    a = EARTH_RADIUS_KM + h;          % circular orbit radius, km
    period_s = 2 * pi * sqrt(a^3 / MU);

    rho = asin(EARTH_RADIUS_KM / a);  % angular radius of Earth from orbit
    if abs(deg2rad(betaDeg)) >= rho
        eclipseFraction = 0.0;        % fully sunlit orbit
    else
        ratio = sqrt(a^2 - EARTH_RADIUS_KM^2) / (a * cosd(betaDeg));
        eclipseFraction = (1/pi) * acos(ratio);
    end

    o = struct();
    o.maxEclipseFraction = mkval(round(eclipseFraction, 4), '');
    o.orbitPeriod_s      = mkval(round(period_s, 1), 's');
    o.orbitPeriod_min    = mkval(round(period_s/60, 2), 'min');
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

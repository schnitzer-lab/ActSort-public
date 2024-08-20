function [system_model, cpu_info] = get_system_info()
    if ispc  % For Windows
        [~, sysModelRaw] = system('wmic csproduct get name');
        [~, cpuInfoRaw] = system('wmic cpu get name');
        system_model = strtrim(extractAfter(sysModelRaw, 'Name'));
        cpu_info = strtrim(extractAfter(cpuInfoRaw, 'Name'));
    elseif ismac  % For macOS
        [~, system_model] = system('sysctl -n hw.model');
        [~, cpu_info] = system('sysctl -n machdep.cpu.brand_string');
        system_model = strtrim(system_model);
        cpu_info = strtrim(cpu_info);
    elseif isunix  % For Linux and other Unix-like systems
        [~, system_model] = system('cat /sys/class/dmi/id/product_name');
        [~, cpuInfoRaw] = system('cat /proc/cpuinfo | grep "model name" | head -1');
        cpu_info = strtrim(extractAfter(cpuInfoRaw, 'model name'));
        system_model = strtrim(system_model);
        if isempty(system_model)  % Some systems might not have this file
            [~, system_model] = system('hostnamectl | grep "Chassis"');
            system_model = strtrim(extractAfter(system_model, 'Chassis:'));
        end
    else
        system_model = 'unknown';
        cpu_info = 'unknown';
    end
end

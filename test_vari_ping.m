clc;
clear;

% Da decidere se fare il ping su più host o su uno solo
%hosts = {'www.google.com', 'www.yahoo.com', 'www.microsoft.com'};
hosts = {'aix-marseille.testdebit.info'};

K_param = 5;
jump = 170; %TODO METTI COME VALORE 34
L_param = 10; 

% Esegue il ping per ogni combinazione di host e parametro
for i = 1:numel(hosts)
    % Initialize an empty table with variable names
    row_number = int32((1472-L_param)/jump);
    % Inizialmente veniva inserito un +1 per far arrivare L_param a 1472.
    % Ma a causa dei 28 Byte di header questa cosa non è corretta.
    %row_number = row_number + 1;
    results = -1 * ones(row_number, 1 + K_param);
    for j = 1:row_number
        command = sprintf('ping -n %d -l %d %s', K_param, L_param, hosts{i});
        disp(command);
        % Esegue il ping e salva il risultato in una stringa
        [status, pingResult] = system(command);
        results(j, 1) = L_param;
        L_param = L_param + jump;
        if status == 0
            % MODIFICA DURATA SULLA BASE DEL TUO COMPUTER
            % (testando con il 'ping www.google.com')
            time = regexp(pingResult, 'durata=\d+ms', 'match');
            time = erase(erase(time, 'ms'), 'durata=');
            disp(time);
            converted_time = str2double(time);
            results(j ,2:6) = converted_time;
        else
            fprintf("errore");
        end
    end

    min_col = min(results(:,2:end), [], 2);
    %disp(min_col);

    avg_col = mean(results(:,2:end), 2);
    %disp(avg_col)

    max_col = max(results(:,2:end), [], 2);
    %disp(max_col);

    % Si passa 0 come parametro indicando che si usa la sample std.
    % Per utilizzare la population std settare il parametro a ???
    std_col = std(results(:,2:end), 0, 2);
    %disp(std_col);

    column_names = {'bytes', 'min', 'avg', 'max', 'std'};
    stats = array2table([results(:,1), min_col, avg_col, max_col, std_col], 'VariableNames', column_names);
    disp(stats);
    

    % --------- Pendenza e intercetta della retta ---------
    coeff = polyfit(stats.bytes, stats.min, 1);
    m = coeff(1); % pendenza
    q = coeff(2); % intercetta
    fprintf('\n\nLa funzione ottenuta tramite polyfit è: %d x + %d\n\n', m, q);


    % --------- Figura con grafici ---------
    figure;

    % Grafico min
    subplot(2, 2, 1);
    scatter(stats.bytes, stats.min); 
    xlabel('Bytes sent');
    ylabel('Min value');

    % La retta ottenuta da polyfit viene aggiunta al grafico di min
    hold on
    x_line = linspace(min(stats.bytes), max(stats.bytes), 100);
    y_line = polyval(coeff, x_line);
    plot(x_line, y_line, 'r');

    % Grafico max
    subplot(2, 2, 2);
    scatter(stats.bytes, stats.max); 
    xlabel('Bytes sent');
    ylabel('Max value');

    % Grafico avg
    subplot(2, 2, 3);
    scatter(stats.bytes, stats.avg); 
    xlabel('Bytes sent');
    ylabel('Avg value');

    % Grafico std
    subplot(2, 2, 4);
    scatter(stats.bytes, stats.std); 
    xlabel('Bytes sent');
    ylabel('Std value');


    % --------- Vengono calcolati i due throughtput ---------
    throughput_bottleneck = 2/m; % Risultato in Byte/ms
    links = 1;  %TODO modify the number of link or calculate it
    throughput = links/m;

end


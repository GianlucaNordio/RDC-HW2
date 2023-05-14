clc;
clear;

% --------- Parametri ---------
host = 'aix-marseille.testdebit.info';
K_param = 10;
jump = 17; %TODO METTI COME VALORE 34
L_param = 10; 


% --------- Tabella con campionamenti ---------

% La dimensione dei pacchetti non arriva a 1472 perché ci sono i 28 Byte di
% header
row_number = int32((1472-L_param)/jump);

% Inizializza una tabella con gli elementi vuoti
results = -1 * ones(row_number, 1 + K_param);
for j = 1:row_number
    command = sprintf('ping -n %d -l %d %s', K_param, L_param, host);
    disp(command);
    % Esegue il ping e salva il risultato in una stringa
    [status, pingResult] = system(command);
    results(j, 1) = L_param;
    L_param = L_param + jump;
    if status == 0
        % MODIFICA LA PAROLA 'durata' SULLA BASE DEL TUO COMPUTER
        % (testando con il 'ping www.google.com')
        time = regexp(pingResult, 'durata=\d+ms', 'match');
        time = erase(erase(time, 'ms'), 'durata=');
        disp(time);
        converted_time = str2double(time);
        results(j ,2:end) = converted_time;
    else
        fprintf("errore");
    end
end

% --------- Pendenza e intercetta della retta ---------
min_col = min(results(:,2:end), [], 2);
avg_col = mean(results(:,2:end), 2);
max_col = max(results(:,2:end), [], 2);
% Si passa 0 come parametro indicando che si usa la sample std.
std_col = std(results(:,2:end), 0, 2);

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



% ---------  Determinazione numero link ---------
links = -1;
counter = 1;
while counter <= 50
link_command = sprintf('ping -n 3 -l 10 -i %d %s', counter, host);
[state, output] = system(link_command);
    if state == 0
        % Il comando è stato eseguito correttamente, analizziamo l'output
        match = regexp(output, 'TTL=', 'match');
        if ~isempty(match)
            % Abbiamo trovato il valore TTL, la connessione ha avuto successo
            links = counter;
            break
        end
    end
    counter = counter + 1;
end

if(links == -1)
    links = input('Impossibile determinare il numero di link in modo automatico!\nInserisci il numero di link: ');
end

fprintf('\n\nIl numero di link utilizzati è: %d\n\n', links);


% ---------  Calcolo due throughtput ---------
throughput_bottleneck = 2/m; % Risultato in Byte/ms
throughput = links/m;


fprintf('Il throughput è: %d\n', throughput);
fprintf('Il throughput del bottleneck è: %d\n', throughput_bottleneck);



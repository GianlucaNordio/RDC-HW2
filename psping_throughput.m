clc;
clear;

% --------- Parametri ---------
host = 'aix-marseille.testdebit.info';
K_param = 1;   %50;
jump = 17*20; %TODO METTI COME VALORE 34
L_param = 10; 


% --------- Tabella con campionamenti ---------

% La dimensione dei pacchetti non arriva a 1472 perché ci sono i 28 Byte di
% header
row_number = int32((1472-L_param)/jump);

bytes_col = zeros(row_number, 1);
std_col = zeros(row_number, 1);
max_col = zeros(row_number, 1);
min_col = zeros(row_number, 1);
avg_col = zeros(row_number, 1);


for j = 1:row_number
    % TODO AGGIUNGI L
    command = sprintf('psping -w 0 -n %d -l %d %s', K_param, L_param, host);
    disp(command);
    % Esegue il ping e salva il risultato in una stringa
    [status, pingResult] = system(command);
    disp(pingResult); 
    pattern = '\d+\.\d+ms';
    time = regexp(pingResult, pattern, 'match');
    time = erase(time, 'ms');
    converted_time = str2double(time);
    disp(converted_time);
    min_col(j) = converted_time(end-2);
    max_col(j) = converted_time(end-1);
    avg_col(j) = converted_time(end);
    std_col(j) = std(converted_time(:,1:(end-3)), 0, 2);
    bytes_col(j) = L_param;
    L_param = L_param + jump;
end


% --------- Pendenza e intercetta della retta ---------
coeff = polyfit(bytes_col, min_col, 1);
m = coeff(1); % pendenza
q = coeff(2); % intercetta
fprintf('\n\nLa funzione ottenuta tramite polyfit è: %d x + %d\n\n', m, q);


% --------- Figura con grafici ---------
figure;

% Grafico min
subplot(2, 2, 1);
scatter(bytes_col, min_col); 
xlabel('Bytes sent');
ylabel('Min value');

% La retta ottenuta da polyfit viene aggiunta al grafico di min
hold on
x_line = linspace(min(bytes_col), max(bytes_col), 100);
y_line = polyval(coeff, x_line);
plot(x_line, y_line, 'r');

% Grafico max
subplot(2, 2, 2);
scatter(bytes_col, max_col); 
xlabel('Bytes sent');
ylabel('Max value');

% Grafico avg
subplot(2, 2, 3);
scatter(bytes_col, avg_col); 
xlabel('Bytes sent');
ylabel('Avg value');

% Grafico std
subplot(2, 2, 4);
scatter(bytes_col, std_col); 
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


fprintf('Il throughput è: %.2f byte/ms = %.2f Mbit/s\n', throughput, throughput*8/1000);
fprintf('Il throughput del bottleneck è: %.2f Byte/ms = %.2f Mbit/s\n', throughput_bottleneck, throughput_bottleneck*8/1000);

% ---------  Writing all data into a xls file ---------
column_names = {'bytes', 'min', 'avg', 'max', 'std'};
result_matrix = array2table([bytes_col, min_col, avg_col, max_col, std_col], 'VariableNames', column_names);
writetable(result_matrix,'psping_throughput_results.xls','WriteVariableNames', true);




clc;
clear;
% Definizione del nome o dell'indirizzo IP del server da testare
%server_name = 'paris.testdebit.info';
server_name = 'aix-marseille.testdebit.info';

counter = 1;

while counter <= 50
    % Definizione del comando ping da eseguire
    command = sprintf('ping -n 5 -l 10 -i %d %s', counter, server_name);
    
    % Esecuzione del comando ping e acquisizione dell'output
    [status, output] = system(command);
    
    % Analisi dell'output per determinare se la connessione ha avuto successo
    if status == 0
        % Il comando è stato eseguito correttamente, analizziamo l'output
        match = regexp(output, 'TTL=', 'match');
        if ~isempty(match)
            % Abbiamo trovato il valore TTL, la connessione ha avuto successo
            fprintf('Connessione al server %s riuscita con n = %d\n', server_name, counter);
            break
        else
            % Non abbiamo trovato il valore TTL, la connessione ha fallito
            fprintf('Connessione al server %s fallita con n = %d\n', server_name, counter);
        end
    else
        % Il comando ha restituito un errore, la connessione ha fallito
        fprintf('Connessione al server %s fallita con n = %d\n', server_name, counter);
    end
    counter = counter + 1;
end

fprintf('\n\nIl TTL necessario calcolato per effettuare la connessione è %d\n\n', counter);


% Il risultato del comando "tracert" viene mostrato
fprintf('Si effettua ora il controllo tramite il comando tracert:\n')
command = sprintf('tracert %s', server_name);
[status, output] = system(command);
if(status) 
    fprintf('Errore\n');
else
    disp(output);
end
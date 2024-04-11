/*
Autores: Asier Lara Arroyo, Mirhan Futsi Segura, Raul Mensat Martínez.
Enlace gitub: https://github.com/asierlara/Trabajo2_PL-SQL.git
*/
drop table clientes cascade constraints;
drop table abonos   cascade constraints;
drop table eventos  cascade constraints;
drop table reservas	cascade constraints;

drop sequence seq_abonos;
drop sequence seq_eventos;
drop sequence seq_reservas;


-- Creación de tablas y secuencias

create table clientes(
	NIF	varchar(9) primary key,
	nombre	varchar(20) not null,
	ape1	varchar(20) not null,
	ape2	varchar(20) not null
);


create sequence seq_abonos;

create table abonos(
	id_abono	integer primary key,
	cliente  	varchar(9) references clientes,
	saldo	    integer not null check (saldo>=0)
    );

create sequence seq_eventos;

create table eventos(
	id_evento	integer  primary key,
	nombre_evento		varchar(20),
    fecha       date not null,
	asientos_disponibles	integer  not null
);

create sequence seq_reservas;

create table reservas(
	id_reserva	integer primary key,
	cliente  	varchar(9) references clientes,
    evento      integer references eventos,
	abono       integer references abonos,
	fecha	date not null
);


	
-- Procedimiento a implementar para realizar la reserva
CREATE OR REPLACE PROCEDURE reservar_evento(
    arg_NIF_cliente VARCHAR,
    arg_nombre_evento VARCHAR,
    arg_fecha DATE)
IS
    -- Variables para verificar la existencia y estado del evento y el cliente.
    v_cliente_exist NUMBER;
    v_evento_id NUMBER;
    v_asientos_disponibles NUMBER;
    v_saldo_abono NUMBER;
    v_evento_encontrado BOOLEAN := FALSE;
BEGIN
    -- Comprobar si el cliente existe
    SELECT COUNT(*) INTO v_cliente_exist FROM clientes WHERE NIF = arg_NIF_cliente;
    IF v_cliente_exist = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cliente inexistente');
    END IF;
    
    -- Comprobar si la fecha del evento ya ha pasado
    IF arg_fecha < SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20001, 'No se pueden reservar eventos pasados.');
    END IF;
    
    -- Comprobar si el evento existe y obtener sus datos
    BEGIN
        SELECT id_evento, asientos_disponibles INTO v_evento_id, v_asientos_disponibles
        FROM eventos WHERE nombre_evento = arg_nombre_evento AND fecha = arg_fecha;
        v_evento_encontrado := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_evento_encontrado := FALSE;
    END;

    -- Lanzar error si el evento no existe
    IF NOT v_evento_encontrado THEN
        RAISE_APPLICATION_ERROR(-20003, 'El evento ' || arg_nombre_evento || ' no existe');
    END IF;

    -- Comprobar si hay asientos disponibles y el saldo del abono
    SELECT saldo INTO v_saldo_abono FROM abonos WHERE cliente = arg_NIF_cliente;
    IF v_asientos_disponibles <= 0 OR v_saldo_abono <= 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Saldo en abono insuficiente o no hay asientos disponibles');
    END IF;
    
    -- Si se pasan todas las comprobaciones, actualizar saldo, asientos y crear la reserva
    UPDATE abonos SET saldo = saldo - 1 WHERE cliente = arg_NIF_cliente;
    UPDATE eventos SET asientos_disponibles = asientos_disponibles - 1 WHERE id_evento = v_evento_id;
    INSERT INTO reservas (id_reserva, cliente, evento, abono, fecha)
    VALUES (seq_reservas.NEXTVAL, arg_NIF_cliente, v_evento_id, (SELECT id_abono FROM abonos WHERE cliente = arg_NIF_cliente), SYSDATE);
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Imprimir el código y mensaje de error.
        DBMS_OUTPUT.PUT_LINE('Error: SQLCODE=' || SQLCODE || ' SQLERRM=' || SQLERRM);
        -- Relanzar la excepción para no perder la información sobre la misma.
        RAISE;
END;
/



------ Deja aquí tus respuestas a las preguntas del enunciado:
/*
    P4.1: La fiabilidad de la comprobación en el paso 2 hacia el paso 3 puede verse afectada por 
    operaciones concurrentes. Aunque se verifique la disponibilidad y el saldo en el paso 2, estas 
    condiciones pueden cambiar antes de que se efectúe la reserva en el paso 3 debido a otras 
    transacciones que se comprometan (commit) en el ínterin, especialmente en un entorno de alta 
    concurrencia. Esto se debe al fenómeno conocido como "lecturas no repetibles" o "condiciones de 
    carrera", donde los datos leídos en una transacción cambian antes de que esta termine debido a 
    otras transacciones.
    */

    /*
    P4.2: Sí, la ejecución concurrente del procedimiento 'reservar_evento' puede llevar a situaciones 
    donde, después de pasar las comprobaciones iniciales, otras instancias del mismo procedimiento (o 
    diferentes transacciones) modifiquen los datos (como el saldo del abono o los asientos disponibles 
    del evento) antes de que se realice la reserva. Esto podría resultar en reservas que sobrepasen la 
    capacidad del evento o que utilicen saldo de abono que ya no está disponible. Este problema se 
    relaciona con el concepto de aislamiento en transacciones de bases de datos.
    */

    /*
    P4.3 y P4.4: La estrategia de programación utilizada se centra en el manejo de concurrencia a través 
    del uso de bloqueos explícitos o "FOR UPDATE" en las consultas SELECT, cuando es aplicable, para 
    prevenir condiciones de carrera. Además, se emplean verificaciones de existencia y estado antes de 
    proceder a la actualización de datos, y el manejo de excepciones para asegurar la integridad de los 
    datos y proporcionar retroalimentación específica sobre errores. Este enfoque se refleja en el uso de 
    transacciones controladas con COMMIT y ROLLBACK adecuados, y en el diseño cuidadoso de la lógica 
    para anticipar y manejar situaciones de error.
    */

    /*
    P4.5: Otra estrategia podría ser el uso de procedimientos almacenados con transacciones serializables 
    o el uso de mecanismos de bloqueo más granulares. Esto podría implicar ajustar el nivel de 
    aislamiento de la transacción para serializable, asegurando que cada transacción se ejecute con la 
    visión completa de los datos como si fuera la única en el sistema en ese momento. 

    Pseudocódigo:
    BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    -- Verificar la existencia del cliente y del evento, y que el evento no ha pasado.
    -- Comprobar saldo del abono y asientos disponibles.
    -- Si pasa todas las comprobaciones, realizar la reserva.
    -- Actualizar el saldo del abono, los asientos disponibles y añadir la reserva.
    COMMIT TRANSACTION;

    Esta aproximación minimiza los problemas de concurrencia pero puede aumentar el tiempo de espera 
    para el bloqueo de recursos, lo que podría no ser ideal en sistemas con alta demanda.
    */


create or replace
procedure reset_seq( p_seq_name varchar )
is
    l_val number;
begin
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by -' || l_val || 
                                                          ' minvalue 0';
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by 1 minvalue 0';

end;
/


create or replace procedure inicializa_test is
begin
  reset_seq( 'seq_abonos' );
  reset_seq( 'seq_eventos' );
  reset_seq( 'seq_reservas' );
        
  
    delete from reservas;
    delete from eventos;
    delete from abonos;
    delete from clientes;
    
       
		
    insert into clientes values ('12345678A', 'Pepe', 'Perez', 'Porras');
    insert into clientes values ('11111111B', 'Beatriz', 'Barbosa', 'Bernardez');
    
    insert into abonos values (seq_abonos.nextval, '12345678A',10);
    insert into abonos values (seq_abonos.nextval, '11111111B',0);
    
    insert into eventos values ( seq_eventos.nextval, 'concierto_la_moda', date '2024-6-27', 200);
    insert into eventos values ( seq_eventos.nextval, 'teatro_impro', date '2024-7-1', 50);
       
    commit;
end;
/

exec inicializa_test;

-- Completa el test

create or replace procedure test_reserva_evento is
    -- Variable para capturar los mensajes de error
    v_error_msg VARCHAR2(4000);
BEGIN
    -- Caso 1: Reserva correcta, se realiza
    BEGIN
        inicializa_test;
        -- Intenta realizar una reserva correcta
        reservar_evento('12345678A', 'concierto_la_moda', TO_DATE('2024-06-27', 'YYYY-MM-DD'));
        DBMS_OUTPUT.PUT_LINE('Caso 1: Reserva correcta, se realiza - PASÓ');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Caso 1: Falló - ' || SQLERRM);
    END;
    
   -- Caso 2: Evento pasado
BEGIN
    inicializa_test;
    -- Aunque el evento 'concierto_la_moda' existe para '2024-06-27', intentamos reservarlo para una fecha pasada
    -- Esto debería lanzar el error esperado por intentar reservar un evento pasado.
    reservar_evento('12345678A', 'concierto_la_moda', TO_DATE('2022-06-27', 'YYYY-MM-DD'));
EXCEPTION
    WHEN OTHERS THEN
        v_error_msg := SQLERRM;
        IF SQLCODE = -20001 THEN
            DBMS_OUTPUT.PUT_LINE('Caso 2: Evento pasado - PASÓ');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Caso 2: Falló - ' || v_error_msg);
        END IF;
END;
    
    -- Caso 3: Evento inexistente
    BEGIN
        inicializa_test;
        -- Intenta realizar una reserva para un evento inexistente
        reservar_evento('12345678A', 'evento_fantasma', TO_DATE('2024-06-27', 'YYYY-MM-DD'));
    EXCEPTION
        WHEN OTHERS THEN
            v_error_msg := SQLERRM;
            IF SQLCODE = -20003 THEN
                DBMS_OUTPUT.PUT_LINE('Caso 3: Evento inexistente - PASÓ');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Caso 3: Falló - ' || v_error_msg);
            END IF;
    END;
    
    -- Caso 4: Cliente inexistente
    BEGIN
        inicializa_test;
        -- Intenta realizar una reserva con un cliente inexistente
        reservar_evento('NIF_Fantasma', 'concierto_la_moda', TO_DATE('2024-06-27', 'YYYY-MM-DD'));
    EXCEPTION
        WHEN OTHERS THEN
            v_error_msg := SQLERRM;
            IF SQLCODE = -20002 THEN
                DBMS_OUTPUT.PUT_LINE('Caso 4: Cliente inexistente - PASÓ');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Caso 4: Falló - ' || v_error_msg);
            END IF;
    END;
    
    -- Caso 5: El cliente no tiene saldo suficiente
    BEGIN
        inicializa_test;
        -- Intenta realizar una reserva con un cliente que no tiene saldo suficiente
        reservar_evento('11111111B', 'teatro_impro', TO_DATE('2024-07-01', 'YYYY-MM-DD'));
    EXCEPTION
        WHEN OTHERS THEN
            v_error_msg := SQLERRM;
            IF SQLCODE = -20004 THEN
                DBMS_OUTPUT.PUT_LINE('Caso 5: Saldo en abono insuficiente - PASÓ');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Caso 5: Falló - ' || v_error_msg);
            END IF;
    END;
END;
/


set serveroutput on;
exec test_reserva_evento;

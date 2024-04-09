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
    v_cliente_exist NUMBER;
    v_evento_id NUMBER;
    v_evento_fecha DATE;
    v_asientos_disponibles NUMBER;
    v_saldo_abono NUMBER;
BEGIN
    -- Comprobar si el cliente existe
    SELECT COUNT(*) INTO v_cliente_exist FROM clientes WHERE NIF = arg_NIF_cliente;
    IF v_cliente_exist = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cliente inexistente');
    END IF;
    
    -- Comprobar si el evento existe y obtener sus datos
    SELECT id_evento, fecha, asientos_disponibles INTO v_evento_id, v_evento_fecha, v_asientos_disponibles
    FROM eventos WHERE nombre_evento = arg_nombre_evento AND fecha = arg_fecha;
    
    -- Comprobar si el evento ha pasado
    IF v_evento_fecha < SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20001, 'No se pueden reservar eventos pasados.');
    END IF;
    
    -- Comprobar si hay asientos disponibles y el saldo del abono
    -- Se asume que el abono está directamente relacionado con el NIF del cliente y es único.
    SELECT saldo INTO v_saldo_abono FROM abonos WHERE cliente = arg_NIF_cliente;
    IF v_asientos_disponibles = 0 OR v_saldo_abono = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Saldo en abono insuficiente o no hay asientos disponibles');
    END IF;
    
    -- Si se pasan todas las comprobaciones, actualizar saldo, asientos y crear la reserva
    -- Actualizar saldo en abono
    UPDATE abonos SET saldo = saldo - 1 WHERE cliente = arg_NIF_cliente;
    
    -- Actualizar asientos disponibles
    UPDATE eventos SET asientos_disponibles = asientos_disponibles - 1 WHERE id_evento = v_evento_id;
    
    -- Insertar la reserva
    INSERT INTO reservas (id_reserva, cliente, evento, abono, fecha)
    VALUES (seq_reservas.NEXTVAL, arg_NIF_cliente, v_evento_id, (SELECT id_abono FROM abonos WHERE cliente = arg_NIF_cliente), SYSDATE);
    
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'El evento ' || arg_nombre_evento || ' no existe');
END;
/


------ Deja aquí tus respuestas a las preguntas del enunciado:
-- * P4.1
--
-- * P4.2
--
-- * P4.3
--
-- * P4.4
--
-- * P4.5
-- 


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
begin
	 
  --caso 1 Reserva correcta, se realiza
  begin
    inicializa_test;
  end;
  
  
  --caso 2 Evento pasado
  begin
    inicializa_test;
  end;
  
  --caso 3 Evento inexistente
  begin
    inicializa_test;
  end;
  

  --caso 4 Cliente inexistente  
  begin
    inicializa_test;
  end;
  
  --caso 5 El cliente no tiene saldo suficiente
  begin
    inicializa_test;
  end;

  
end;
/


set serveroutput on;
exec test_reserva_evento;

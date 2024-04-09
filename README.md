
# Trabajo 2: PL/SQL - Reservas para Festival de Música y Teatro
Trabajo realizado por:
- Raúl Mensat Martínez
- Mirhan Futsi Segura
- Asier Lara Arroyo
## Descripción de la Práctica
Se presenta el caso de una empresa de eventos que organiza un festival de música y teatro. Se ha creado un sistema de abonos para que más personas puedan disfrutar de los espectáculos. Cada abono permite asistir a un máximo de 10 eventos. Se proporcionan tablas y secuencias para facilitar la implementación.

## Tablas:

1. **Clientes**: Almacena información sobre los clientes.
2. **Abonos**: Contiene los abonos adquiridos por los clientes.
3. **Evento**: Registra los eventos del festival.
4. **Reservas**: Guarda las reservas realizadas por los clientes.

## Secuencias:
- `seq_abonos`: Genera claves primarias para la tabla de abonos.
- `seq_evento`: Genera claves primarias para la tabla de eventos.
- `seq_reservas`: Genera claves primarias para la tabla de reservas.
Se proporciona un script (reservaEvento_enun.sql) que crea las tablas, secuencias y procedimientos almacenados necesarios.

## Objetivos

- Implementar una transacción PL/SQL para reservar plaza en un evento del festival.
- Desarrollar una serie de comprobaciones para garantizar la validez de las reservas, incluyendo la disponibilidad de asientos y el saldo de los abonos.
- Manejar excepciones específicas relacionadas con la reserva de eventos.
- Asegurar la consistencia de las operaciones de reserva mediante el adecuado manejo de transacciones.
- Implementar una batería de tests para validar la funcionalidad desarrollada.

## Procedimientos Almacenados

- `reset_seq(p_seq_name varchar)`: Resetea las secuencias.
- `inicializa_test`: Reinicia el contenido de la base de datos con filas de prueba.
- `test_reserva_evento`: Procedimiento almacenado con tests automáticos.


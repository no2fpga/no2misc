Simple I2C master
=================

This is a simple I2C master that doesn't support multi-master or
clock-stretching, so make sure you don't require those !

It's little more than a shift register to avoid having to bit bang
every bit, so the software still needs to do most of the work for
higher level.

The basic idea is you issue commands and read their responses.

The core can also be instanciated with and without FIFO. If FIFO
are present you can queue multiple commands without blocking and
read the responses later. Note that if you have `gr` bit set (to
capture responses, see below), you need to make _sure_ not to
queue too many before reading the responses depending on the FIFO
depth so you don't hang the bus !


Memory Map
----------

### Command (Write Only, addr `0x00`)

```text
,-----------------------------------------------------------------------------------------------,
|31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10| 9| 8| 7| 6| 5| 4| 3| 2| 1| 0|
|-----------------------------------------------------------------------------------------------|
|                       /                       |gr|//| cmd |    /   |ai|       data            |
'-----------------------------------------------------------------------------------------------'

 * [15]    - gr   : Get Response
 * [13:12] - cmd  : RX FIFO overflow
 * [8]     - ai   : Ack In    (Only for READ)
 * [ 7:0]  - data : Data Byte (Only for WRITE)
```

The supported commands are :

* `00 = START` : Issue a start condition
* `01 = STOP`  : Issue a write condition
* `10 = WRITE` : Write byte `data` to the bus and sample the ack bit as `ack_out` in the response
* `11 = READ`  : Read byte from the bus and send `ack_in` as the ack bit.

The `gr` bit only makes sense in FIFO mode. If it's not set, any response from the command
is simply dropped and put in the response FIFO.

The `ai` bit is the value of the ack bit itself. Meaning `0` is `ACK` and `1` is `NAK`.


### Response (Read Only, addr `0x00`)

```text
,-----------------------------------------------------------------------------------------------,
|31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10| 9| 8| 7| 6| 5| 4| 3| 2| 1| 0|
|-----------------------------------------------------------------------------------------------|
|rv|cr|                        /                                     |ao|       data            |
'-----------------------------------------------------------------------------------------------'

 * [31]  - rv   : Response Valid
 * [30]  - cr   : Command ready
 * [9]   - eo   : Err Out   (Time-out occured)
 * [8]   - ao   : Ack Out   (Only for WRITE)
 * [7:0] - data : Data Byte (Only for READ)
```

In FIFO mode, reading from this register will dequeue a response (assuming there was one),
and the `rv` bit indicates if the FIFO was empty or not.

Without FIFO it always returns the response of the last command and `rv` indicates if that
is valid or if the command is still being executed.

The `cr` bit indicates in both cases if a new command can be submitted safely. For non-FIFO
mode that bit will match `rv`, and for FIFO mode, this indicates that the command FIFO is not
full.

The `eo` bit indicates that the core waited too long for SCL to rise, meaning some device
held it low for too long. Only valid if both clock stretching support and timeout counter
were enabled in the core build.

The `ao` bit is the value of the ack bit itself. Meaning `0` is `ACK` and `1` is `NAK`.


### Response peek (Read Only, addr `0x04`)

This is the same register as `0x00` but in FIFO mode it doesn't actually de-queue the response
(if any). This allows for instance to check if the `cr` is set or not with no side effects.

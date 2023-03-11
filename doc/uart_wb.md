Simple wishbone UART
====================

This is a simple UART that only supports 8N1 mode with a configurable divider.
FIFOs are included (default are 512 bytes deep)


Memory Map
----------

### CSR (Read/Write, addr `0x04`)

```text
,-----------------------------------------------------------------------------------------------,
|31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10| 9| 8| 7| 6| 5| 4| 3| 2| 1| 0|
|-----------------------------------------------------------------------------------------------|
|re|ro|te|tf|                     /                         |            div                    |
'-----------------------------------------------------------------------------------------------'

 * [31]   - re  : RX FIFO empty
 * [30]   - ro  : RX FIFO overflow
 * [29]   - te  : TX FIFO empty
 * [28]   - tf  : TX FIFO full
 * [11:0] - div : Divider value minus 2
```

Notes:
  * The `ro` Read Overflow bit is auto-cleared on read
  * The effective baudrate will be `sys_clk / (div + 2)`


### TX data (Write Only, addr `0x00`)

```text
,-----------------------------------------------------------------------------------------------,
|31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10| 9| 8| 7| 6| 5| 4| 3| 2| 1| 0|
|-----------------------------------------------------------------------------------------------|
|                              /                                        |      tx_data          |
'-----------------------------------------------------------------------------------------------'

 * [7:0] - tx_data : Byte to queue for transmission
```

Attempts to write to a full TX FIFO will block the bus until space is available.


### RX data (Read Only, addr `0x00`)

```text
,-----------------------------------------------------------------------------------------------,
|31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10| 9| 8| 7| 6| 5| 4| 3| 2| 1| 0|
|-----------------------------------------------------------------------------------------------|
| e|                           /                                        |      rx_data          |
'-----------------------------------------------------------------------------------------------'

 * [31  ] - e       : Empty flag
 * [ 7:0] - rx_data : Received byte (assuming e=0)
```

Attempts to read from an empty RX FIFO will return immediately with the MSB bit set to indicate
no valid data was read.


### Notes

This block also supports instanciating with a 16 bit wide wishbone bus.
In which case, some of the bits normally in the MSB of the 32b words are
moved down by 16 bits. It should be fairly obvious what those are from the
descriptions above.

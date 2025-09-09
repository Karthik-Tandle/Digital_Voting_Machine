![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

## 4-Bit Digital Voting Machine

A TinyTapeout-compliant digital voting machine that supports up to 4 candidates with vote counting, winner detection, reset, and debug output.

Features
--------------
Supports 4 candidates (one-hot input).

4 modes of operation: Voting, Counting, Reset, Test.

Displays the winner in one-hot format.

Voting complete indicator when counting.

Debug output shows total_votes % 8.

I/O Mapping
---------------
Inputs (ui_in)
| Bits   | Name    | Description                                                     |
| ------ | ------- | --------------------------------------------------------------- |
| [3:0] | voter   | Candidate selection (one-hot: 0001, 0010, 0100, 1000)           |
| [4]   | confirm | Vote confirm button                                             |
| [5]   | rst     | Asynchronous reset                                              |
| [7:6] | mode    | Mode select (00 = Voting, 01 = Counting, 10 = Reset, 11 = Test) |

Outputs (uo_out)
----------------
| Bits   | Name             | Description                              |
| ------ | ---------------- | ---------------------------------------- |
| [3:0] | winner           | Winning candidate (one-hot)              |
| [4]   | voting\_complete | High when in Counting mode               |
| [7:5] | debug            | Lower 3 bits of total vote count (`% 8`) |

Modes of Operation
--------------------
| Mode (`ui_in[7:6]`) | Action      | Winner Output  | Voting Complete | Debug (votes % 8) |
| ------------------- | ----------- | -------------- | --------------- | ----------------- |
| `00` (Voting)       | Store votes | `0000`         | `0`             | Active            |
| `01` (Counting)     | Show result | One-hot winner | `1`             | Active            |
| `10` (Reset)        | Clear all   | `0000`         | `0`             | `000`             |
| `11` (Test)         | Debug only  | `0000`         | `0`             | Active            |


# How it Works

Voter presses one candidate button and confirms with the confirm button.

On confirm, the candidate’s vote counter increments and total votes increase.

Winner selection logic compares all four counters to display the highest.

Reset mode clears all counters.

Debug output shows total votes modulo 8 (3-bit wraparound).

# How to Test

Reset: Set mode = 10 to clear all votes.

Voting: Set mode = 00, press candidate button + confirm to cast votes.

Counting: Set mode = 01, check winner output matches highest votes and debug shows votes % 8.

Test: Set mode = 11, only debug count is shown.

Reset again: Verify everything clears to zero.

Example Debug Count (Votes % 8)
| Total Votes | Debug Output (`uo_out[7:5]`) |
| ----------- | ---------------------------- |
| 0           | 000                          |
| 1           | 001                          |
| 2           | 010                          |
| 3           | 011                          |
| 4           | 100                          |
| 5           | 101                          |
| 6           | 110                          |
| 7           | 111                          |
| 8           | 000 (wraps around)           |

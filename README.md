# Design and Implementation of an AMBA AHB-to-APB Bridge

## 📖 Project Overview

This project details the complete Register-Transfer Level (RTL) design and hardware implementation of a synthesizable **AHB-to-APB Bridge**. [cite_start]In modern System-on-Chip (SoC) designs, the Advanced Microcontroller Bus Architecture (AMBA) is a standard for on-chip communication[cite: 77, 91]. [cite_start]It defines protocols like the Advanced High-performance Bus (AHB) for high-speed modules (e.g., processors, DMA) and the Advanced Peripheral Bus (APB) for low-bandwidth peripherals (e.g., UART, timers) [cite: 94-97].

[cite_start]The AHB-to-APB bridge is an essential infrastructure component that enables a high-speed AHB master to communicate seamlessly with slower APB slaves[cite: 79, 101]. This design acts as an AHB slave, accepting transactions, and as an APB master, driving those transactions to the target peripheral. [cite_start]A key feature of this bridge is its ability to handle asynchronous clock domains, ensuring robust data transfer between the high-frequency AHB domain (`HCLK`) and the low-frequency APB domain (`PCLK`)[cite: 80, 104].

---

## 🏗️ System Architecture and Design

The bridge is architected as a set of modular and interconnected Verilog components. [cite_start]The top-level `main.v` module instantiates the AHB slave interface, the bridge core, the APB master interface, and a sample APB slave memory [cite: 33-37, 137].

!(doc/elaborated_design.png)

### Module Descriptions

#### 🔹 `ahb_slave.v`
[cite_start]This module serves as the front-end interface to the AHB bus[cite: 143]. Its primary responsibilities are:
* [cite_start]**Transaction Detection**: It monitors AHB signals `HSEL` and `HTRANS` to detect a valid transfer request[cite: 145, 359].
* [cite_start]**Data Capture**: When a valid transaction is initiated, it captures the address (`HADDR`), write data (`HWDATA`), and control signals (`HWRITE`) [cite: 145, 362-363].
* [cite_start]**Packetization**: It formats the captured information into a 41-bit packet: `{HWRITE, HWDATA, HADDR}` and asserts `H_Valid` to signal the packet is ready for the bridge[cite: 146, 367].
* [cite_start]**Stalling**: It uses the `Bridge_Ready` signal from the bridge as backpressure, stalling the AHB master by de-asserting `HREADYOUT` if the bridge's internal FIFO is full[cite: 147, 359].

***

#### 🔹 `bridge.v`
[cite_start]This is the core of the design, responsible for synchronization and decoupling between the AHB and APB domains[cite: 149]. It consists of two primary components:
* [cite_start]**Request FIFO (`WRITE_FIFO`)**: An asynchronous FIFO that safely passes the 41-bit transaction packet from the `ahb_slave` (in the `HCLK` domain) to the `apb_master` (in the `PCLK` domain) [cite: 151-152]. [cite_start]It provides a `wr_fifo_full` signal to the AHB slave for backpressure[cite: 5, 153].
* [cite_start]**Response FIFO (`READ_FIFO`)**: An asynchronous FIFO that transfers read data from the `apb_master` (in the `PCLK` domain) back to the `ahb_slave` (in the `HCLK` domain)[cite: 7, 155].

***

#### 🔹 `apb_master.v`
[cite_start]This module reads transaction packets from the bridge and drives the APB bus[cite: 157]. [cite_start]It operates using a three-state state machine[cite: 158, 254]:
* [cite_start]**`IDLE`**: Waits for a valid transaction request (`P_Valid`) from the bridge's request FIFO[cite: 159]. [cite_start]Upon receiving a request, it latches the packet and moves to the `SETUP` state[cite: 262].
* [cite_start]**`SETUP`**: A single-cycle state where it asserts `PSEL` and places the address (`PADDR`), write data (`PWDATA`), and direction (`PWRITE`) on the APB bus [cite: 161, 268-269].
* [cite_start]**`ACCESS`**: Asserts `PENABLE` and holds the bus signals until the selected APB slave responds by asserting `PREADY`[cite: 162, 270]. [cite_start]For a read operation, it writes the received `PRDATA` into the bridge's response FIFO upon completion [cite: 163, 270-271].

***

#### 🔹 `apb_slave.v`
[cite_start]This is a simple memory model acting as a target peripheral on the APB bus[cite: 165].
* [cite_start]It contains a 256x32-bit internal memory array[cite: 166, 279].
* [cite_start]When `PSEL` and `PENABLE` are high, it services the request[cite: 166]. [cite_start]For a write, it stores `PWDATA`; for a read, it provides data on `PRDATA` [cite: 167, 282-284].
* [cite_start]It includes a configurable `wait_count` register to introduce wait states, simulating a slow peripheral and testing the bridge's ability to handle stalls[cite: 168, 279, 281].

---

### Clock Domain Crossing (CDC)

[cite_start]Robustly transferring data between the `HCLK` and `PCLK` domains is the most critical function of the bridge[cite: 170]. [cite_start]This design employs industry-standard asynchronous FIFOs to prevent metastability and ensure data integrity[cite: 171].
* [cite_start]The **request path** (AHB to APB) uses a FIFO written by `HCLK` and read by `PCLK`[cite: 172].
* [cite_start]The **response path** (APB to AHB) uses a FIFO written by `PCLK` and read by `HCLK`[cite: 173].
* [cite_start]The `async_fifo.v` module uses Gray code pointers to safely pass the write and read pointer values across clock domains, which is a proven technique for avoiding synchronization failures [cite: 174, 292, 296, 302, 308-309].

---

## 🔬 Implementation and Verification

The design's correctness was validated through both simulation and on-chip hardware implementation.

### Simulation-Based Verification
[cite_start]Initial functional verification was performed using a Verilog testbench (`tb_main.v`)[cite: 180].
* [cite_start]**Architecture**: The testbench instantiates the DUT and generates `HCLK` and `PCLK` clocks, typically with a 2:1 frequency ratio[cite: 181].
* [cite_start]**Transaction Generation**: It uses `write_trans` and `read_trans` tasks to model an AHB master, initiating write and read operations to random addresses [cite: 182-183, 326-340].
* [cite_start]**Self-Checking**: The testbench maintains a local memory model to store the data written[cite: 184]. [cite_start]After performing writes, it reads from the same addresses and compares the returned `HRDATA` against the stored values, automatically reporting on the correctness of each transaction [cite: 185-187, 346-347].

### FPGA Prototyping and Hardware Verification
[cite_start]The final validation involved implementing the design on a **Xilinx Zynq-7000 based Zedboard**[cite: 202].
* [cite_start]**IP Packaging**: The entire bridge design was encapsulated into a custom IP with an AXI4-Lite slave interface to connect with the Zynq Processing System (PS)[cite: 203].
* [cite_start]**PS-PL Integration**: The custom IP was placed in the Programmable Logic (PL) and connected to the PS via an AXI Interconnect[cite: 205].
* [cite_start]**Software Control**: A C program running on the ARM Cortex-A9 processor (PS) controlled the DUT by writing to its memory-mapped registers, initiating AHB transactions [cite: 206-207]. [cite_start]Results were read back and printed to a serial terminal[cite: 208].
* [cite_start]**Hardware Debugging**: A Xilinx Integrated Logic Analyzer (ILA) core was used to monitor key internal signals in real-time, which was crucial for debugging and confirming correct operation on the FPGA [cite: 209-210].

---

## 🛠️ Tools Used

* [cite_start]**Simulation & Implementation**: Xilinx Vivado Design Suite [cite: 213-214]
* [cite_start]**Hardware Platform**: Digilent ZedBoard Zynq-7000 Development Board [cite: 215]

---

## 🚀 How to Run the Simulation

1.  **Clone the repository:**
    ```sh
    git clone [https://github.com/PrasadSanap11/Design-and-Implementation-of-AHB-to-APB-Bridge.git](https://github.com/PrasadSanap11/Design-and-Implementation-of-AHB-to-APB-Bridge.git)
    cd Design-and-Implementation-of-AHB-to-APB-Bridge
    ```
2.  **Open in a simulator:** Launch a Verilog simulator like Xilinx Vivado.
3.  **Add sources:** Add all Verilog files from the `rtl/` and `tb/` directories to your simulation project.
4.  **Set top module:** Set `tb_main` as the top-level module for the simulation.
5.  **Run Simulation:** Execute the simulation. The testbench console will display the status of the write and read transactions, indicating if the read data is correct.

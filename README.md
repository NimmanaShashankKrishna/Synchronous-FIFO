# 🔁 Synchronous FIFO — Verilog Implementation

[![Language](https://img.shields.io/badge/Language-Verilog-blue)](https://en.wikipedia.org/wiki/Verilog)
[![Tool](https://img.shields.io/badge/Tool-Xilinx%20Vivado%202025.1-orange)](https://www.xilinx.com/products/design-tools/vivado.html)
[![FPGA](https://img.shields.io/badge/Target-xc7vx485tffg1157--1-green)](https://www.xilinx.com)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

---

## 📌 Overview

A **Synchronous FIFO (First-In First-Out)** is a memory buffer where both the **write and read operations share the same clock**. It is used widely in pipelined processors, on-chip data buffering, and stream processing logic where producer and consumer run on the same clock domain.

Unlike the Asynchronous FIFO, no clock domain crossing is required — making the design simpler but restricted to single-clock systems.

---

## 🏗️ Architecture

```
         clk ──────────────────────────────────────────►
         rst_n ─────────────────────────────────────────►

         w_en ──►┌──────────────────────────────┐──► full
         data_in─►│                              │
                  │     SYNCHRONOUS FIFO         │
         r_en ──►│                              │──► empty
                  │  ┌──────────────────────┐   │
                  │  │   FIFO Memory Array  │   │──► data_out
                  │  │  mem[0..DEPTH-1]     │   │
                  │  └──────────────────────┘   │
                  │    ↑              ↑          │
                  │  wr_ptr        rd_ptr        │
                  │  (increments   (increments   │
                  │   on write)     on read)     │
                  └──────────────────────────────┘
```

---

## 📐 Module Description

| Module | Description |
|--------|-------------|
| `sync_fifo` | Top-level — contains memory array, write/read pointers, full/empty logic |
| `tb_sync_fifo` | Testbench — drives write, read, and edge-case scenarios |

---

## ⚙️ Parameters & Port Description

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `DATA_WIDTH` | 8 | Width of each data word in bits |
| `DEPTH` | 8 | Number of entries in the FIFO |
| `PTR_WIDTH` | 3 | Pointer width = log₂(DEPTH) |

### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | Input | 1 | System clock (single clock domain) |
| `rst_n` | Input | 1 | Active-low synchronous reset |
| `w_en` | Input | 1 | Write enable |
| `r_en` | Input | 1 | Read enable |
| `data_in` | Input | 8 | Data to write into FIFO |
| `data_out` | Output | 8 | Data read from FIFO |
| `full` | Output | 1 | FIFO full flag — do not write when HIGH |
| `empty` | Output | 1 | FIFO empty flag — do not read when HIGH |

---

## 🔑 Key Design Concepts

### 1. Write & Read Pointers
Both pointers are **binary counters** on the same clock — no Gray code needed since there's no CDC (Clock Domain Crossing).

```verilog
// Write pointer increments when write enabled and not full
if (w_en && !full)
    wr_ptr <= wr_ptr + 1;

// Read pointer increments when read enabled and not empty
if (r_en && !empty)
    rd_ptr <= rd_ptr + 1;
```

### 2. Full Flag
FIFO is full when the write pointer **wraps around** and equals the read pointer (with a 1-extra MSB trick or counter approach):
```
FULL when: (wr_ptr + 1) == rd_ptr   [using extra count bit]
```

### 3. Empty Flag
FIFO is empty when write and read pointers are **equal**:
```
EMPTY when: wr_ptr == rd_ptr
```

### 4. Simultaneous Read/Write (Same Clock)
Both read and write can happen in the **same clock cycle** as long as FIFO is neither full (for write) nor empty (for read):
```verilog
if (w_en && !full && r_en && !empty) begin
    mem[wr_ptr] <= data_in;   // write
    data_out    <= mem[rd_ptr]; // read
end
```

---

## 🧪 Testbench & Test Cases

---

### Test Case 1 — Reset Behavior
**What this tests:**
- `rst_n` asserted LOW → All pointers reset to 0
- `full = 0`, `empty = 1` after reset
- `data_out` goes to default/undefined until first valid read

> 📸 Add your waveform screenshot here:
> `![TC1 - Reset](images/tc1_reset.png)`

---

### Test Case 2 — Sequential Write Until Full
**What this tests:**
- `w_en = 1`, `r_en = 0`
- Data written sequentially: `0x01, 0x02, ..., 0x08` (8 locations)
- `full` flag asserts HIGH after 8th write
- Write pointer wraps: `wr_ptr` goes `0 → 1 → 2 → ... → 7 → 0`
- Write-when-full is **ignored** (no overflow)

> 📸 Add your waveform screenshot here:
> `![TC2 - Sequential Write](images/tc2_write_full.png)`

---

### Test Case 3 — Sequential Read Until Empty
**What this tests:**
- Starting from a full FIFO: `r_en = 1`, `w_en = 0`
- Data read out in FIFO order (first written = first read)
- `empty` flag asserts HIGH after last read
- Read-when-empty is **ignored** (no underflow)

> 📸 Add your waveform screenshot here:
> `![TC3 - Sequential Read](images/tc3_read_empty.png)`

---

### Test Case 4 — Simultaneous Read and Write
**What this tests:**
- `w_en = 1` and `r_en = 1` at the same time (FIFO neither full nor empty)
- FIFO depth stays **constant** (1 in, 1 out per cycle)
- `full` and `empty` flags remain LOW
- Verifies pipelined throughput capability

> 📸 Add your waveform screenshot here:
> `![TC4 - Simultaneous R/W](images/tc4_simultaneous.png)`

---

## 📁 Repository Structure

```
Synchronous-FIFO/
├── README.md                  ← This file
├── src/
│   └── sync_fifo.v            ← FIFO design (syncfifo.v)
├── testbench/
│   └── tb_sync_fifo.v         ← Testbench
├── images/
│   ├── tc1_reset.png          ← Waveform: Reset behavior
│   ├── tc2_write_full.png     ← Waveform: Write until full
│   ├── tc3_read_empty.png     ← Waveform: Read until empty
│   └── tc4_simultaneous.png   ← Waveform: Simultaneous R/W
└── docs/
    └── design_notes.md
```

---

## 🚀 How to Simulate (Xilinx Vivado)

1. Open **Vivado 2025.1**
2. Create a new project → Add `src/sync_fifo.v` as design source
3. Add `testbench/tb_sync_fifo.v` as simulation source
4. Set `tb_sync_fifo` as the top simulation module
5. Click **Run Simulation → Run Behavioral Simulation**

---

## ⚖️ Synchronous vs Asynchronous FIFO — Quick Comparison

| Feature | Synchronous FIFO | Asynchronous FIFO |
|---------|-----------------|-------------------|
| Clock domains | 1 (shared) | 2 (independent) |
| Complexity | Low | High |
| CDC handling | Not needed | Gray code + 2FF sync |
| Use case | Single-clock pipelines | Cross-domain data transfer |
| Full/Empty logic | Simple binary compare | Gray pointer comparison |

---

## 📚 References

- Cummings, C. E. (2002). *Simulation and Synthesis Techniques for Asynchronous FIFO Design*. SNUG 2002.
- Xilinx UG901 — Vivado Design Suite User Guide
- Weste & Harris — *CMOS VLSI Design*, Chapter 10

---

## 👤 Author

**Nimmana Shashank Krishna**  
B.E / B.Tech — VLSI / ECE / EEE  
📧 nimmana.shashank@example.com  
🔗 [LinkedIn](https://www.linkedin.com/in/nimmana-shashank-krishna-423516258) | [GitHub](https://github.com/NimmanaShashankKrishna)

---

*This project was designed and simulated using Xilinx Vivado 2025.1 on xc7vx485tffg1157-1 FPGA target.*

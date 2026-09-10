# UART Receiver Testbench Do File
# ModelSim/QuestaSim script for UART RX testing

# Create work library
vlib work
vmap work work

# Compile source files
vlog ./rtl/uart_rx.v
vlog ./rtl/Edge_detector.v
vlog ./rtl/serial_to_parallel.v


# Compile testbench files
vlog ./tb/uart_rx_tb.v

# Load design
vsim work.uart_rx_tb -voptargs=+acc

# Add waves for monitoring
add wave -noupdate -divider "System Signals"
add wave -noupdate -color Yellow /uart_rx_tb/clk
add wave -noupdate -color Yellow /uart_rx_tb/arst_n
add wave -noupdate -color Yellow /uart_rx_tb/rst

add wave -noupdate -divider "UART RX Signals"
add wave -noupdate -color Cyan /uart_rx_tb/rx_en
add wave -noupdate -color Cyan /uart_rx_tb/baudiv
add wave -noupdate -color Green /uart_rx_tb/rx
add wave -noupdate -color Magenta /uart_rx_tb/rx_busy
add wave -noupdate -color Magenta /uart_rx_tb/rx_done
add wave -noupdate -color Orange /uart_rx_tb/rx_err
add wave -noupdate -color Cyan /uart_rx_tb/rx_data

add wave -noupdate -divider "DUT Internal Signals"
add wave -noupdate -color Orange /uart_rx_tb/dut/state
add wave -noupdate -color Orange /uart_rx_tb/dut/next_state
add wave -noupdate -color Orange /uart_rx_tb/dut/bit_idx
add wave -noupdate -color Orange /uart_rx_tb/dut/baud_cnt
add wave -noupdate -color Orange /uart_rx_tb/dut/sipo
add wave -noupdate -color Orange /uart_rx_tb/dut/rx_d1
add wave -noupdate -color Orange /uart_rx_tb/dut/rx_d2

# Configure wave display
configure wave -timelineunits ns
WaveRestoreZoom {0 ps} {1000 ns}

# Run simulation
run -all

# Display results
echo "UART Receiver Test Completed"
echo "Check transcript for detailed results"

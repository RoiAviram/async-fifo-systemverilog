# =========================================================
# 1. Primary Clock Definitions
# =========================================================
# wr_clk: 100MHz (Period = 10.0ns, 50% duty cycle)
create_clock -period 10.000 -name wr_clk -waveform {0.000 5.000} [get_ports wr_clk]

# rd_clk: 40MHz (Period = 25.0ns, 50% duty cycle)
create_clock -period 25.000 -name rd_clk -waveform {0.000 12.500} [get_ports rd_clk]

# =========================================================
# 2. CDC Max Delay Constraints (Datapath-Only)
# =========================================================
# Limits total routing latency across domains without checking Setup/Hold.
# Delay is set to the destination clock period to guarantee fast propagation.

# Write domain to Read domain (wr_clk -> rd_clk): Target limit is 25.0ns
set_max_delay -datapath_only \
    -from [get_cells -hier -filter {NAME =~ u_wptr_full/*reg[*]}] \
    -to   [get_cells -hier -filter {NAME =~ u_sync_w2r/sync_stage1_reg[*]}] 25.000
    
# Read domain to Write domain (rd_clk -> wr_clk): Target limit is 10.0ns
set_max_delay -datapath_only \
    -from [get_cells -hier -filter {NAME =~ u_rptr_empty/*reg[*]}] \
    -to   [get_cells -hier -filter {NAME =~ u_sync_r2w/sync_stage1_reg[*]}] 10.000

# =========================================================
# 3. Bus Skew Constraints (Critical for Gray Code Integrity)
# =========================================================
# Ensures that the skew between any two bits of the Gray pointer bus 
# does not exceed the destination clock cycle, preventing multi-bit transitions.

set_bus_skew \
    -from [get_cells -hier -filter {NAME =~ u_wptr_full/*reg[*]}] \
    -to   [get_cells -hier -filter {NAME =~ u_sync_w2r/sync_stage1_reg[*]}] 5.000

set_bus_skew \
    -from [get_cells -hier -filter {NAME =~ u_rptr_empty/*reg[*]}] \
    -to   [get_cells -hier -filter {NAME =~ u_sync_r2w/sync_stage1_reg[*]}] 5.000
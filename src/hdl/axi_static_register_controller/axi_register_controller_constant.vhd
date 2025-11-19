library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package axi_static_register_controller_constant is

    -- Registers parameters : 
    constant REGISTER_SIZE_BYTES : natural := 4;
    constant ADDRESS_SIZE_BYTES  : natural := 2;
    constant REG_ADDR_WIDTH      : natural := ADDRESS_SIZE_BYTES * 8;
    constant C_S_AXI_DATA_WIDTH  : natural := 32;    
    constant C_S_AXI_STRB_WIDTH  : natural := C_S_AXI_DATA_WIDTH / 8;
    constant C_S_AXI_ADDR_WIDTH  : natural := 32;
    constant ADDR_LSB            : natural := (C_S_AXI_DATA_WIDTH / 32) + 1;
    constant OPT_MEM_ADDR_BITS   : natural := 16 - ADDR_LSB - 1;
    

    -- Address list : 
    -- c: write register adrr with offset
    constant REGISTER_CTRL_WR_ADDR   : std_logic_vector(REG_ADDR_WIDTH -1 downto 0) := X"0000";
    constant REGISTER_ALTI_WR_ADDR   : std_logic_vector(REG_ADDR_WIDTH -1 downto 0) := X"0004";
    constant REGISTER_SPED_WR_ADDR   : std_logic_vector(REG_ADDR_WIDTH -1 downto 0) := X"0008";
    constant REGISTER_TPCH_WR_ADDR   : std_logic_vector(REG_ADDR_WIDTH -1 downto 0) := X"000C";
    constant REGISTER_HEAD_WR_ADDR   : std_logic_vector(REG_ADDR_WIDTH -1 downto 0) := X"0010";
    constant REGISTER_THRT_R_ADDR   : std_logic_vector(REG_ADDR_WIDTH -1 downto 0) := X"0080";
    constant REGISTER_CPCH_R_ADDR   : std_logic_vector(REG_ADDR_WIDTH -1 downto 0) := X"0084";
    constant REGISTER_ROLL_R_ADDR   : std_logic_vector(REG_ADDR_WIDTH -1 downto 0) := X"0088";
    constant REGISTER_CYAW_R_ADDR   : std_logic_vector(REG_ADDR_WIDTH -1 downto 0) := X"008C";
    

    -- Reg default value : 
    -- c: write register default value in bit
    constant REGISTER_CTRL_WR_DEFAULT: std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0) := "00000000000000000000000000000000";
    constant REGISTER_ALTI_WR_DEFAULT: std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0) := "00000000000000000000000000000000";
    constant REGISTER_SPED_WR_DEFAULT: std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0) := "00000000000000000000000000000000";
    constant REGISTER_TPCH_WR_DEFAULT: std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0) := "00000000000000000000000000000000";
    constant REGISTER_HEAD_WR_DEFAULT: std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0) := "00000000000000000000000000000000";
    constant REGISTER_THRT_R_DEFAULT: std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0) := "00000000000000000000000000000000";
    constant REGISTER_CPCH_R_DEFAULT: std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0) := "00000000000000000000000000000000";
    constant REGISTER_ROLL_R_DEFAULT: std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0) := "00000000000000000000000000000000";
    constant REGISTER_CYAW_R_DEFAULT: std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0) := "00000000000000000000000000000000";
    
    






end package;

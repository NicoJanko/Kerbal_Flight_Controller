library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

use work.axi_static_register_controller_constant.all;

entity axi_static_register_controller is
  generic (
    REGISTER_SIZE_BYTES : natural := 4;
    ADDRESS_SIZE_BYTES  : natural := 2;
    REG_ADDR_WIDTH      : natural := 16;
    C_S_AXI_DATA_WIDTH  : natural := 32;
    C_S_AXI_STRB_WIDTH  : natural := 4;
    C_S_AXI_ADDR_WIDTH  : natural := 32;
    ADDR_LSB            : natural := 2;
    OPT_MEM_ADDR_BITS   : natural := 13
  );
  port(
    -- AXI BUS interface --
    S_AXI_ACLK    : in  std_logic;                                           -- Global Clock Signal
    S_AXI_ARESETN : in  std_logic;                                           -- Global Reset Signal. This Signal is Active LOW
    S_AXI_AWADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);   -- Write address (issued by master, acceped by Slave)
    S_AXI_AWVALID : in  std_logic;                                           -- Write address valid.
    S_AXI_AWREADY : out std_logic;                                           -- Write address ready.
    S_AXI_WDATA   : in  std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);   -- Write data (issued by master, acceped by Slave) 
    S_AXI_WSTRB   : in  std_logic_vector(C_S_AXI_STRB_WIDTH - 1 downto 0);   -- Write strobes.
    S_AXI_WVALID  : in  std_logic;                                           -- Write valid
    S_AXI_WREADY  : out std_logic;                                           -- Write ready. 
    S_AXI_BRESP   : out std_logic_vector(1 downto 0);                        -- Write response.
    S_AXI_BVALID  : out std_logic;                                           -- Write response valid.
    S_AXI_BREADY  : in  std_logic;                                           -- Response ready.
    S_AXI_ARADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);   -- Read address (issued by master, acceped by Slave)
    S_AXI_ARVALID : in  std_logic;                                           -- Read address valid.
    S_AXI_ARREADY : out std_logic;                                           -- Read address ready.
    S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);   -- Read data (issued by slave)
    S_AXI_RRESP   : out std_logic_vector(1 downto 0);                        -- Read response. 
    S_AXI_RVALID  : out std_logic;                                           -- Read valid.
    S_AXI_RREADY  : in  std_logic;                                           -- Read ready.
    -- Registers interface --
    -- c: write read register
    axi_register_thrt_r   : in std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
    axi_register_thrt_r_fifo_read: out std_logic;
    axi_register_thrt_r_fifo_empty: in std_logic;
    axi_register_cpch_r   : in std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
    axi_register_cpch_r_fifo_read: out std_logic;
    axi_register_cpch_r_fifo_empty: in std_logic;
    axi_register_roll_r   : in std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
    axi_register_roll_r_fifo_read: out std_logic;
    axi_register_roll_r_fifo_empty: in std_logic;
    axi_register_cyaw_r   : in std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
    axi_register_cyaw_r_fifo_read: out std_logic;
    axi_register_cyaw_r_fifo_empty: in std_logic;

    -- c: write write/read register
    axi_register_ctrl_wr   : out std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
    axi_register_alti_wr   : out std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
    axi_register_sped_wr   : out std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
    axi_register_tpch_wr   : out std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
    axi_register_head_wr   : out std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0)

    
  );
end axi_static_register_controller;

architecture rtl of axi_static_register_controller is

  -- AXI4LITE signals
  signal wresp_q       : std_logic_vector(1 downto 0);
  signal wresp_waddr_q : std_logic;
  signal wresp_raddr_q : std_logic;
  signal wresp_full_q  : std_logic;
  signal wresp_empty_q : std_logic;
  signal slv_reg_wren  : std_logic;
  signal axi_rdata_s   : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  signal axi_rdata0_q  : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  signal axi_rdata1_q  : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  signal rresp_s       : std_logic;
  signal rresp_q       : std_logic_vector(1 downto 0);
  signal rresp_waddr_q : std_logic;
  signal rresp_raddr_q : std_logic;
  signal rresp_full_q  : std_logic;
  signal rresp_empty_q : std_logic;
  signal slv_reg_rden  : std_logic;
  signal read_addr     : std_logic_vector(OPT_MEM_ADDR_BITS downto 0);

  -- Internal buf, used for write sequence 
  -- c: write internal buffer 
  signal register_ctrl_wr_q                        : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  signal register_alti_wr_q                        : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  signal register_sped_wr_q                        : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  signal register_tpch_wr_q                        : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  signal register_head_wr_q                        : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  signal register_thrt_r_q                        : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  signal register_cpch_r_q                        : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  signal register_roll_r_q                        : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  signal register_cyaw_r_q                        : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);

  -- Internal signals 
  -- c: write internal signals
  signal register_ctrl_wr_internal                        : std_logic_vector(31 downto 0);
  signal register_alti_wr_internal                        : std_logic_vector(31 downto 0);
  signal register_sped_wr_internal                        : std_logic_vector(31 downto 0);
  signal register_tpch_wr_internal                        : std_logic_vector(31 downto 0);
  signal register_head_wr_internal                        : std_logic_vector(31 downto 0);
  signal register_thrt_r_internal                        : std_logic_vector(31 downto 0);
  signal register_cpch_r_internal                        : std_logic_vector(31 downto 0);
  signal register_roll_r_internal                        : std_logic_vector(31 downto 0);
  signal register_cyaw_r_internal                        : std_logic_vector(31 downto 0);
  

  -- Internal FIFO signals
  -- c: write internal fifo signals
  signal fifo_thrt_r_read                        : std_logic := '0';
  signal fifo_thrt_r_empty                     :std_logic;
  signal fifo_cpch_r_read                        : std_logic := '0';
  signal fifo_cpch_r_empty                     :std_logic;
  signal fifo_roll_r_read                        : std_logic := '0';
  signal fifo_roll_r_empty                     :std_logic;
  signal fifo_cyaw_r_read                        : std_logic := '0';
  signal fifo_cyaw_r_empty                     :std_logic;
  


  --

begin

  -- I/O Connections assignments
  S_AXI_AWREADY <= slv_reg_wren;
  S_AXI_WREADY  <= slv_reg_wren;
  S_AXI_BRESP   <= '0' & wresp_q(0) when wresp_raddr_q='0' else '0' & wresp_q(1);
  S_AXI_BVALID  <= not(wresp_empty_q);
  S_AXI_ARREADY <= not(rresp_full_q);
  S_AXI_RDATA   <= axi_rdata0_q when rresp_raddr_q='0' else axi_rdata1_q;
  S_AXI_RRESP   <= '0' & rresp_q(0) when rresp_raddr_q='0' else '0' & rresp_q(1);
  S_AXI_RVALID  <= not(rresp_empty_q);



  -- for read only registers (readonly from PS, writable only from PL)
    -- c: write read register assignement
  register_thrt_r_internal                   <= axi_register_thrt_r;
  fifo_thrt_r_empty                            <= axi_register_thrt_r_fifo_empty;
  axi_register_thrt_r_fifo_read              <= fifo_thrt_r_read;
  register_cpch_r_internal                   <= axi_register_cpch_r;
  fifo_cpch_r_empty                            <= axi_register_cpch_r_fifo_empty;
  axi_register_cpch_r_fifo_read              <= fifo_cpch_r_read;
  register_roll_r_internal                   <= axi_register_roll_r;
  fifo_roll_r_empty                            <= axi_register_roll_r_fifo_empty;
  axi_register_roll_r_fifo_read              <= fifo_roll_r_read;
  register_cyaw_r_internal                   <= axi_register_cyaw_r;
  fifo_cyaw_r_empty                            <= axi_register_cyaw_r_fifo_empty;
  axi_register_cyaw_r_fifo_read              <= fifo_cyaw_r_read;

  
    -- for write registers (both read/write from PS but readonly from PS)
    -- c: write internal buffer assignement
  axi_register_ctrl_wr                   <= register_ctrl_wr_internal;
  axi_register_alti_wr                   <= register_alti_wr_internal;
  axi_register_sped_wr                   <= register_sped_wr_internal;
  axi_register_tpch_wr                   <= register_tpch_wr_internal;
  axi_register_head_wr                   <= register_head_wr_internal;

    -- Write buf decoding (for write registers)
    -- c: write write/read register buffer decoding
  register_ctrl_wr_internal                   <= register_ctrl_wr_q(31 downto 0);
  register_alti_wr_internal                   <= register_alti_wr_q(31 downto 0);
  register_sped_wr_internal                   <= register_sped_wr_q(31 downto 0);
  register_tpch_wr_internal                   <= register_tpch_wr_q(31 downto 0);
  register_head_wr_internal                   <= register_head_wr_q(31 downto 0);

  ----------------------------
  -- Write register process
  ----------------------------

  slv_reg_wren <= S_AXI_WVALID and S_AXI_AWVALID and not(rresp_full_q);

  p_write : process(S_AXI_ACLK)

    variable loc_addr : std_logic_vector(OPT_MEM_ADDR_BITS downto 0);

  begin
    if(S_AXI_ACLK'event and S_AXI_ACLK='1') then
      loc_addr                                := S_AXI_AWADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
      if(S_AXI_ARESETN='0') then
        -- port to internal buf
        -- c: write default value assignement
       register_ctrl_wr_q                        <= REGISTER_CTRL_WR_DEFAULT;
       register_alti_wr_q                        <= REGISTER_ALTI_WR_DEFAULT;
       register_sped_wr_q                        <= REGISTER_SPED_WR_DEFAULT;
       register_tpch_wr_q                        <= REGISTER_TPCH_WR_DEFAULT;
       register_head_wr_q                        <= REGISTER_HEAD_WR_DEFAULT;
       register_thrt_r_q                        <= REGISTER_THRT_R_DEFAULT;
       register_cpch_r_q                        <= REGISTER_CPCH_R_DEFAULT;
       register_roll_r_q                        <= REGISTER_ROLL_R_DEFAULT;
       register_cyaw_r_q                        <= REGISTER_CYAW_R_DEFAULT;

        wresp_q                               <= (others => '0');
      elsif(slv_reg_wren='1') then
        if(wresp_waddr_q='0') then
          wresp_q(0) <= '0';
        else
          wresp_q(1) <= '0';
        end if;
        case loc_addr is
        -- check the adress of the request
        -- c: write write logic

        when REGISTER_CTRL_WR_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) => 
            for byte_index in 0 to C_S_AXI_STRB_WIDTH - 1 loop
              if(S_AXI_WSTRB(byte_index)='1') then
                register_ctrl_wr_q((byte_index * 8) + 7 downto byte_index * 8) <= S_AXI_WDATA((byte_index * 8) + 7 downto byte_index * 8);
              end if;
            end loop;


        when REGISTER_ALTI_WR_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) => 
            for byte_index in 0 to C_S_AXI_STRB_WIDTH - 1 loop
              if(S_AXI_WSTRB(byte_index)='1') then
                register_alti_wr_q((byte_index * 8) + 7 downto byte_index * 8) <= S_AXI_WDATA((byte_index * 8) + 7 downto byte_index * 8);
              end if;
            end loop;


        when REGISTER_SPED_WR_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) => 
            for byte_index in 0 to C_S_AXI_STRB_WIDTH - 1 loop
              if(S_AXI_WSTRB(byte_index)='1') then
                register_sped_wr_q((byte_index * 8) + 7 downto byte_index * 8) <= S_AXI_WDATA((byte_index * 8) + 7 downto byte_index * 8);
              end if;
            end loop;


        when REGISTER_TPCH_WR_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) => 
            for byte_index in 0 to C_S_AXI_STRB_WIDTH - 1 loop
              if(S_AXI_WSTRB(byte_index)='1') then
                register_tpch_wr_q((byte_index * 8) + 7 downto byte_index * 8) <= S_AXI_WDATA((byte_index * 8) + 7 downto byte_index * 8);
              end if;
            end loop;


        when REGISTER_HEAD_WR_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) => 
            for byte_index in 0 to C_S_AXI_STRB_WIDTH - 1 loop
              if(S_AXI_WSTRB(byte_index)='1') then
                register_head_wr_q((byte_index * 8) + 7 downto byte_index * 8) <= S_AXI_WDATA((byte_index * 8) + 7 downto byte_index * 8);
              end if;
            end loop;


        when REGISTER_THRT_R_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) => 
            for byte_index in 0 to C_S_AXI_STRB_WIDTH - 1 loop
              if(S_AXI_WSTRB(byte_index)='1') then
                register_thrt_r_q((byte_index * 8) + 7 downto byte_index * 8) <= S_AXI_WDATA((byte_index * 8) + 7 downto byte_index * 8);
              end if;
            end loop;


        when REGISTER_CPCH_R_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) => 
            for byte_index in 0 to C_S_AXI_STRB_WIDTH - 1 loop
              if(S_AXI_WSTRB(byte_index)='1') then
                register_cpch_r_q((byte_index * 8) + 7 downto byte_index * 8) <= S_AXI_WDATA((byte_index * 8) + 7 downto byte_index * 8);
              end if;
            end loop;


        when REGISTER_ROLL_R_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) => 
            for byte_index in 0 to C_S_AXI_STRB_WIDTH - 1 loop
              if(S_AXI_WSTRB(byte_index)='1') then
                register_roll_r_q((byte_index * 8) + 7 downto byte_index * 8) <= S_AXI_WDATA((byte_index * 8) + 7 downto byte_index * 8);
              end if;
            end loop;


        when REGISTER_CYAW_R_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) => 
            for byte_index in 0 to C_S_AXI_STRB_WIDTH - 1 loop
              if(S_AXI_WSTRB(byte_index)='1') then
                register_cyaw_r_q((byte_index * 8) + 7 downto byte_index * 8) <= S_AXI_WDATA((byte_index * 8) + 7 downto byte_index * 8);
              end if;
            end loop;

          
          when others =>
            if(wresp_waddr_q='0') then
              wresp_q(0) <= '1';
            else
              wresp_q(1) <= '1';
            end if;
        end case;
      end if;
    end if;
  end process;

  -- Implement write response logic generation

  p_axi_wresp : process(S_AXI_ACLK)

  begin
    if(S_AXI_ACLK'event and S_AXI_ACLK='1') then
      if(S_AXI_ARESETN='0') then
        wresp_empty_q <= '1';
        wresp_full_q  <= '0';
        wresp_raddr_q <= '0';
        wresp_waddr_q <= '0';
      else
        if(wresp_empty_q='0' and S_AXI_BREADY='1') then
          wresp_raddr_q <= not(wresp_raddr_q);
          wresp_full_q  <= '0';
          if(wresp_full_q='0' and slv_reg_wren='0') then
            wresp_empty_q <= '1';
          end if;
        end if;
        if(slv_reg_wren='1') then
          wresp_empty_q <= '0';
          wresp_waddr_q <= not(wresp_waddr_q);
          if(wresp_empty_q='0' and S_AXI_BREADY='0') then
            wresp_full_q <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  ---------------------------
  -- Read register process
  ---------------------------

  p_axi_rresp : process(S_AXI_ACLK)

  begin
    if(S_AXI_ACLK'event and S_AXI_ACLK='1') then
      if(S_AXI_ARESETN='0') then
        rresp_empty_q <= '1';
        rresp_full_q  <= '0';
        rresp_raddr_q <= '0';
        rresp_waddr_q <= '0';
      else
        if(rresp_empty_q='0' and S_AXI_RREADY='1') then
          rresp_raddr_q <= not(rresp_raddr_q);
          rresp_full_q  <= '0';
          if(rresp_full_q='0' and slv_reg_rden='0') then
            rresp_empty_q <= '1';
          end if;
        end if;
        if(slv_reg_rden='1') then
          rresp_empty_q <= '0';
          rresp_waddr_q <= not(rresp_waddr_q);
          if(rresp_empty_q='0' and S_AXI_RREADY='0') then
            rresp_full_q <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Implement memory mapped register select and read logic generation

  slv_reg_rden <= S_AXI_ARVALID and not(rresp_full_q);
  p_read_sync : process(S_AXI_ACLK)

  begin
    if(S_AXI_ACLK'event and S_AXI_ACLK='1') then
      if(S_AXI_ARESETN='0') then
        axi_rdata0_q <= (others => '0');
        axi_rdata1_q <= (others => '0');
        rresp_q      <= (others => '0');
      elsif(slv_reg_rden='1') then
        if(rresp_waddr_q='0') then
          rresp_q(0)   <= rresp_s;
          axi_rdata0_q <= axi_rdata_s;
        else
          rresp_q(1)   <= rresp_s;
          axi_rdata1_q <= axi_rdata_s;
        end if;
      end if;
    end if;
  end process;

  read_addr <= S_AXI_ARADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);

  p_read_async : process(
                    -- c: internal buff in process & read addr
                  register_ctrl_wr_internal,
                  register_alti_wr_internal,
                  register_sped_wr_internal,
                  register_tpch_wr_internal,
                  register_head_wr_internal,
                  register_thrt_r_internal,
                  register_cpch_r_internal,
                  register_roll_r_internal,
                  register_cyaw_r_internal,
                   
                   read_addr)

  begin
    rresp_s <= '0';
    case read_addr is
        -- check the adress for the async read
        -- c: write read logic

    when REGISTER_CTRL_WR_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
        axi_rdata_s <= register_ctrl_wr_internal;

        
    when REGISTER_ALTI_WR_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
        axi_rdata_s <= register_alti_wr_internal;

        
    when REGISTER_SPED_WR_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
        axi_rdata_s <= register_sped_wr_internal;

        
    when REGISTER_TPCH_WR_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
        axi_rdata_s <= register_tpch_wr_internal;

        
    when REGISTER_HEAD_WR_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
        axi_rdata_s <= register_head_wr_internal;

        
    when REGISTER_THRT_R_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
        axi_rdata_s <= register_thrt_r_internal;
        if (fifo_thrt_r_empty = '0') then
          rresp_s     <= '1';
        end if;


    when REGISTER_CPCH_R_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
        axi_rdata_s <= register_cpch_r_internal;
        if (fifo_cpch_r_empty = '0') then
          rresp_s     <= '1';
        end if;


    when REGISTER_ROLL_R_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
        axi_rdata_s <= register_roll_r_internal;
        if (fifo_roll_r_empty = '0') then
          rresp_s     <= '1';
        end if;


    when REGISTER_CYAW_R_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
        axi_rdata_s <= register_cyaw_r_internal;
        if (fifo_cyaw_r_empty = '0') then
          rresp_s     <= '1';
        end if;

      
      when others =>
        rresp_s     <= '1';
        axi_rdata_s <= (others => '0');
    end case;
  end process;

-- c: if fifo write fifo read logic
 -- fifo specific sync read
  p_fifo_read_sync : process(S_AXI_ACLK)
  begin
      if rising_edge(S_AXI_ACLK) then
          if S_AXI_ARESETN = '0' then
          -- c: write fifo rst
             fifo_thrt_r_read <= '0';
             fifo_cpch_r_read <= '0';
             fifo_roll_r_read <= '0';
             fifo_cyaw_r_read <= '0';
              
          else
            -- c: write fifo read logic
             fifo_thrt_r_read <= '0';
             fifo_cpch_r_read <= '0';
             fifo_roll_r_read <= '0';
             fifo_cyaw_r_read <= '0';
              -- default no read
              
              

              -- When an AXI read is accepted, and the CPU targets REGISTER_0,
              -- and FIFO is not empty, then pop once
              if slv_reg_rden = '1' then
                case read_addr is
                -- check the adress for the sync read
                -- c: write fifo read reg addr

                when REGISTER_THRT_R_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                    if (fifo_thrt_r_empty = '0') then
                      fifo_thrt_r_read <= '1';  -- one-cycle pulse
                    end if;


                when REGISTER_CPCH_R_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                    if (fifo_cpch_r_empty = '0') then
                      fifo_cpch_r_read <= '1';  -- one-cycle pulse
                    end if;


                when REGISTER_ROLL_R_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                    if (fifo_roll_r_empty = '0') then
                      fifo_roll_r_read <= '1';  -- one-cycle pulse
                    end if;


                when REGISTER_CYAW_R_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                    if (fifo_cyaw_r_empty = '0') then
                      fifo_cyaw_r_read <= '1';  -- one-cycle pulse
                    end if;

                  
                  when others =>
                  -- c: write the default
                       fifo_thrt_r_read <= '0';
                       fifo_cpch_r_read <= '0';
                       fifo_roll_r_read <= '0';
                       fifo_cyaw_r_read <= '0';
                    
                end case;
              end if;
          end if;
      end if;
  end process;

end rtl;

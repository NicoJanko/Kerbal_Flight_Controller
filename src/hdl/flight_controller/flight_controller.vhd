library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity flight_controller is port (
    SCLK            :in std_logic;
    NRST            :in std_logic;
    CTRL            :in std_logic_vector(31 downto 0);
    ALTI            :in std_logic_vector(31 downto 0);
    SPED            :in std_logic_vector(31 downto 0);
    TPCH            :in std_logic_vector(31 downto 0);
    HEAD            :in std_logic_vector(31 downto 0);
    THRT            :out std_logic_vector(31 downto 0);
    THRT_WE         :out std_logic;
    THRT_FULL       :in std_logic;
    CPCH            :out std_logic_vector(31 downto 0);
    CPCH_WE         :out std_logic;
    CPCH_FULL       :in std_logic;
    ROLL            :out std_logic_vector(31 downto 0);
    ROLL_WE         :out std_logic;
    ROLL_FULL       :in std_logic;
    CYAW            :out std_logic_vector(31 downto 0);
    CYAW_WE         :out std_logic;
    CYAW_FULL       :in std_logic
);
end flight_controller;




architecture rtl of flight_controller is 
-- internal buffers
signal ctrl_buff        :std_logic_vector(31 downto 0);
signal altitude_buff        :std_logic_vector(31 downto 0);
signal speed_buff        :std_logic_vector(31 downto 0);
signal Tpitch_buff        :std_logic_vector(31 downto 0);
signal heading_buff        :std_logic_vector(31 downto 0);




signal internal_buf         :std_logic_vector(31 downto 0);



begin

ctrl_buff <= CTRL;
altitude_buff <= ALTI;
speed_buff <= SPED;
Tpitch_buff <= TPCH;
heading_buff <= HEAD;

p_process: process(SCLK)
    begin
        if rising_edge(SCLK) then
            if (NRST = '0') then
                internal_buf <= (others => '0');
            end if;
        end if;
    end process;
end rtl;

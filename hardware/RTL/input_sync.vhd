library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity input_sync is
    generic (
        reset_val : std_logic := '0'
    );
    port (
        ACLK    : in std_logic;
        ARESETN : in std_logic;
        i       : in std_logic;
        o       : out std_logic;
        pe      : out std_logic;
        ne      : out std_logic
    );
end entity;

architecture structural of input_sync is
    signal regA, regB : std_logic;
    signal ipe, ine   : std_logic;
begin

    o <= regB;

    ipe <= '1' when regA = '1' and regB = '0' else '0';
    ine <= '1' when regA = '0' and regB = '1' else '0';

    process (ACLK, ARESETN)
    begin
        if ARESETN = '0' then
            regA <= reset_val;
            regB <= reset_val;
            pe   <= '0';
            ne   <= '0';
        elsif rising_edge(ACLK) then
            regA <= i;
            regB <= regA;
            pe   <= ipe;
            ne   <= ine;
        end if;
    end process;

end architecture;
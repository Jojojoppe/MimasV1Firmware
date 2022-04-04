library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity wb_reg is
    port(
        CLK_I           : in std_logic;
        RST_I           : in std_logic;
        ADR_I           : in std_logic_vector(0 downto 0);
        DAT_I           : in std_logic_vector(31 downto 0);
        DAT_O           : out std_logic_vector(31 downto 0);
        WE_I            : in std_logic;
        SEL_I           : in std_logic_vector(3 downto 0);
        STB_I           : in std_logic;
        ACK_O           : out std_logic;
        CYC_I           : in std_logic;
        STALL_O         : out std_logic;

        reg_output      : out std_logic_vector(31 downto 0)
    );
end entity;

architecture struct of wb_reg is
    signal reg_val : std_logic_vector(31 downto 0);
begin

    reg_output <= reg_val;
    DAT_O <= reg_val;

    STALL_O <= '0';

    process(CLK_I, RST_I)
        variable wb_state : std_logic;
    begin
        if RST_I = '1' then
            reg_val <= (others=>'0');
            wb_state := '0';
            ACK_O <= '0';
        elsif rising_edge(CLK_I) then
            if (STB_I and WE_I and (not wb_state)) = '1' then
                -- WRITE CYCLE
                reg_val <= DAT_I;
                wb_state := '1';
                ACK_O <= '0';
            elsif (STB_I and (not WE_I) and (not wb_state)) = '1' then
                -- READ CYCLE
                wb_state := '1';
                ACK_O <= '0';
            elsif (STB_I and WE_I and wb_state) = '1' then
                -- WRITE CYCLE REPEATING -> SEND ACK
                reg_val <= DAT_I;
                wb_state := '1';
                ACK_O <= '1';
            elsif (STB_I and (not WE_I) and wb_state) = '1' then
                -- READ CYCLE REPEATING -> SEND ACK
                wb_state := '1';
                ACK_O <= '1';
            elsif wb_state = '1' then
                -- SEND ACK
                ACK_O <= '1';
                wb_state := '0';
            else
                -- END OF TRANSACTION
                wb_state := '0';
                ACK_O <= '0';
            end if;
        end if;
    end process;
    -- NOTE: simplest would be to tie ACK_O directly to STB_I

end architecture;
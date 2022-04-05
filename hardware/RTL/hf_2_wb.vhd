library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity hf_2_wb is
    port(
        CLK_I           : in std_logic;
        RST_I           : in std_logic;

        ADR_O           : out std_logic_vector(31 downto 0);
        DAT_O           : out std_logic_vector(31 downto 0);
        DAT_I           : in std_logic_vector(31 downto 0);
        WE_O            : out std_logic;
        SEL_O           : out std_logic_vector(3 downto 0);
        STB_O           : out std_logic;
        ACK_I           : in std_logic;
        CYC_O           : out std_logic;
        STALL_I         : in std_logic;

        EP_DOUT         : in std_logic_vector(7 downto 0);
        EP_VOUT         : in std_logic;
        EP_DIN          : out std_logic_vector(7 downto 0);
        EP_WR           : out std_logic;
        EP_BUSY         : in std_logic
    );
    attribute keep_hierarchy : string;
    attribute keep_hierarchy of hf_2_wb : entity is "yes";
end entity;

architecture structural of hf_2_wb is
    -- Shift registers
    signal sh_cmd : std_logic_vector(7 downto 0);
    signal sh_addr0, sh_addr1, sh_addr2, sh_addr3 : std_logic_vector(7 downto 0);
    signal sh_data0, sh_data1, sh_data2, sh_data3 : std_logic_vector(7 downto 0);
    -- Shift status
    signal sh_stat : std_logic_vector(1 downto 0);
    signal sh_shstat : std_logic_vector(3 downto 0);
    signal sh_start : std_logic;
    signal sh_busy : std_logic;

    signal wb_wr : std_logic;
    signal wb_rd : std_logic;
    signal wb_state : std_logic_vector(1 downto 0);
    signal wb_we : std_logic;
    signal wb_done : std_logic;

    signal wb_reset : std_logic;
    signal wb_data_in : std_logic_vector(31 downto 0);

begin

    process(CLK_I, RST_I)
    begin
        if RST_I='1' then
            sh_cmd <= (others=>'0');
            sh_addr0 <= (others=>'0');
            sh_addr1 <= (others=>'0');
            sh_addr2 <= (others=>'0');
            sh_addr3 <= (others=>'0');
            sh_data0 <= (others=>'0');
            sh_data1 <= (others=>'0');
            sh_data2 <= (others=>'0');
            sh_data3 <= (others=>'0');
            sh_stat <= (others=>'0');
            sh_shstat <= (others=>'0');

            sh_start <= '0';
            sh_busy <= '0';

            EP_WR <= '0';
            EP_DIN <= (others=>'0');

        elsif rising_edge(CLK_I) then
            if EP_VOUT='1' then
                -- New byte is written from endpoint
                case sh_stat is
                    when "00" =>
                        -- CMD
                        sh_cmd <= EP_DOUT;
                        sh_shstat <= "0001";
                        sh_start <= '1';
                    when "01" =>
                        -- ADDR
                        sh_addr3 <= sh_addr2;
                        sh_addr2 <= sh_addr1;
                        sh_addr1 <= sh_addr0;
                        sh_addr0 <= EP_DOUT;
                        sh_shstat <= sh_shstat(2 downto 0) & "0";
                    when "10" =>
                        -- DATA IN
                        sh_data3 <= sh_data2;
                        sh_data2 <= sh_data1;
                        sh_data1 <= sh_data0;
                        sh_data0 <= EP_DOUT;
                        sh_shstat <= sh_shstat(2 downto 0) & "0";
                    when others =>
                        report "Should not come here..." severity failure;
                end case;
            else
                -- Normal operation
                if sh_start='1' and EP_BUSY='0' then
                    sh_start <= '0';
                    case sh_cmd is
                        when x"00" =>
                            -- NOP
                            sh_stat <= "00";
                            sh_busy <= '0';
                        when x"01" =>
                            -- WRITE
                            sh_stat <= "01";
                            sh_busy <= '1';
                        when x"02" =>
                            -- READ
                            sh_stat <= "01";
                            sh_busy <= '1';
                        when others =>
                            report "Unkown command" severity error;
                    end case;
                elsif sh_busy='1' and sh_shstat="0000" then
                    -- End of shift cycle
                    case sh_cmd is
                        when x"00" =>
                            -- NOP
                            sh_stat <= "00";
                            sh_busy <= '0';
                        when x"01" =>
                            -- WRITE
                            case sh_stat is
                                when "01" =>
                                    sh_stat <= "10";
                                    sh_busy <= '1';
                                    sh_shstat <= "0001";
                                when "10" =>
                                    sh_stat <= "00";
                                    sh_busy <= '1';
                                when "00" =>
                                    sh_busy <= '1';
                                    sh_stat <= "11";
                                when "11" =>
                                    if wb_done='1' then
                                        sh_busy <= '0';
                                        sh_stat <= "00";
                                        EP_DIN <= x"AA"; -- OKE RESPONSE
                                        EP_WR <= '1';
                                    else
                                        sh_busy <= '1';
                                        sh_stat <= "11";
                                    end if;
                                when others =>
                                    report "Unreachable" severity failure;
                            end case;
                        when x"02" =>
                            -- READ
                            case sh_stat is
                                when "01" =>
                                    sh_stat <= "00";
                                    sh_busy <= '1';
                                    sh_shstat <= "0000";
                                when "00" =>
                                    if wb_done='1' then
                                        sh_busy <= '1';
                                        sh_stat <= "10";
                                        -- TODO start sending out data
                                    else
                                        sh_busy <= '1';
                                        sh_stat <= "00";
                                    end if;

                                when "10" =>
                                    sh_busy <= '0';
                                    sh_stat <= "00";
                                    EP_DIN <= x"AA"; -- OKE RESPONSE
                                    EP_WR <= '1';
                                when others =>
                                    report "Unreachable" severity failure;
                            end case;
                        when others =>
                            report "Unkown command" severity error;
                    end case;
                else
                    EP_DIN <= x"00";
                    EP_WR <= '0';
                end if;
            end if;
        end if;
    end process;
   
    wb_wr <= '1' when (sh_stat="00" and sh_shstat="0000" and sh_busy='1' and sh_cmd=x"01") else '0';
    wb_rd <= '1' when (sh_stat="00" and sh_shstat="0000" and sh_busy='1' and sh_cmd=x"02") else '0';
    wb_reset <= '1' when sh_cmd=x"00" else '0';

    WE_O <= wb_we;
    process(CLK_I, RST_I, wb_reset)
    begin
        if RST_I='1' or wb_reset='1' then
            ADR_O <= (others=>'0');
            DAT_O <= (others=>'0');
            SEL_O <= (others=>'0');
            CYC_O <= '0';
            STB_O <= '0';

            wb_state <= (others=>'0');
            wb_we <= '0';
            wb_done <= '0';
            wb_data_in <= (others=>'0');
        elsif rising_edge(CLK_I) then
            case wb_state is
                when "00" =>
                    -- IDLE
                    CYC_O <= '0';
                    STB_O <= '0';
                    wb_done <= '0';

                    if wb_wr='1' then
                        -- Start write
                        wb_state <= "01";
                        wb_we <= '1';
                    elsif wb_rd='1' then
                        -- Start read
                        wb_state <= "01";
                    else
                        wb_we <= '0';
                    end if;

                when "01" =>
                    -- BUS REQUEST
                    CYC_O <= '1';
                    STB_O <= '1';
                    ADR_O <= sh_addr3 & sh_addr2 & sh_addr1 & sh_addr0;
                    DAT_O <= sh_data3 & sh_data2 & sh_data1 & sh_data0;
                    wb_data_in <= DAT_I;
                    wb_done <= '0';

                    if ACK_I='1' then
                        wb_state <= "00";
                        wb_done <= '1';
                    elsif STALL_I='0' then
                        wb_state <= "10";
                        wb_done <= '0';
                    else
                        wb_state <= "01";
                        wb_done <= '0';
                    end if;

                when "10" =>
                    -- BUS WAIT
                    CYC_O <= '1';
                    STB_O <= '0';

                    if ACK_I='1' then
                        wb_state <= "00";
                        wb_done <= '1';
                    else
                        wb_state <= "10";
                        wb_done <= '0';
                    end if;

                when others =>
                    report "Unreachable" severity failure;
            end case;
        end if;
    end process;

end architecture;
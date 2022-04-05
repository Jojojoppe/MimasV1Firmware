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
        ERR_I           : in std_logic;

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

    type hfstate_t is (cmd, a0, a1, a2, a3, rd0, rd1, rd2, rd3, sd0, sd1, sd2, sd3, wbstart, wbwait, ret);
    signal hfstate : hfstate_t;

    signal sh_a, sh_d : std_logic_vector(31 downto 0);
    signal hf_cmd : std_logic_vector(7 downto 0);
    signal hf_vout_happened : std_logic;
    signal hf_failure : std_logic;
    signal hf_wr_happened : std_logic;

    signal dbg_hfstate : std_logic_vector(7 downto 0);

    signal wb_write : std_logic;
    signal wb_read : std_logic;
    signal wb_done : std_logic;

    type wbstate_t is (idle, req, waiting);
    signal wbstate : wbstate_t;
    signal wbwrrd : std_logic;
    signal wbrddata : std_logic_vector(31 downto 0);

begin
    
    -- HF state machine
    process(CLK_I, RST_I)
    begin
        if RST_I='1' then
            hfstate <= cmd;
            sh_a <= (others => '0');
            sh_d <= (others => '0');
            hf_vout_happened <= '0';
            hf_wr_happened <= '0';
            EP_DIN <= (others => '0');
            EP_WR <= '0';
            wb_write <= '0';
            wb_read <= '0';
        elsif rising_edge(CLK_I) then
            dbg_hfstate <= std_logic_vector(to_unsigned(hfstate_t'POS(hfstate), 8));
            case hfstate is

                when cmd =>
                    if EP_VOUT='1' then
                        hf_vout_happened <= '1';
                        hf_cmd <= EP_DOUT;
                    elsif hf_vout_happened='1' then
                        hf_vout_happened <= '0';
                        case hf_cmd(3 downto 0) is
                            when x"0"  =>
                                hfstate <= ret;
                            when x"1" =>
                                hfstate <= a3;
                            when x"2" =>
                                hfstate <= a3;
                            when others =>
                                report "Unreachable..." severity failure;
                        end case;
                    end if;

                when ret =>
                    if hf_wr_happened='0' then
                        if hf_failure='1' then
                            EP_DIN <= x"AF";
                        else
                            EP_DIN <= x"A0";
                        end if;
                        EP_WR <='1';
                        hf_wr_happened <= '1';
                    else
                        EP_WR <= '0';
                        if EP_BUSY='0' then
                            hf_wr_happened <= '0';
                            hfstate <= cmd;
                        end if;
                    end if;

                when a3 =>
                    if EP_VOUT='1' then
                        hf_vout_happened <= '1';
                        sh_a <= sh_a(23 downto 0) & EP_DOUT;
                    elsif hf_vout_happened='1' then
                        hf_vout_happened <= '0';
                        hfstate <= a2;
                    end if;
                when a2 =>
                    if EP_VOUT='1' then
                        hf_vout_happened <= '1';
                        sh_a <= sh_a(23 downto 0) & EP_DOUT;
                    elsif hf_vout_happened='1' then
                        hf_vout_happened <= '0';
                        hfstate <= a1;
                    end if;
                when a1 =>
                    if EP_VOUT='1' then
                        hf_vout_happened <= '1';
                        sh_a <= sh_a(23 downto 0) & EP_DOUT;
                    elsif hf_vout_happened='1' then
                        hf_vout_happened <= '0';
                        hfstate <= a0;
                    end if;
                when a0 =>
                    if EP_VOUT='1' then
                        hf_vout_happened <= '1';
                        sh_a <= sh_a(23 downto 0) & EP_DOUT;
                    elsif hf_vout_happened='1' then
                        hf_vout_happened <= '0';
                        case hf_cmd(3 downto 0) is
                            when x"1" =>
                                hfstate <= rd3;
                            when x"2" =>
                                hfstate <= wbstart;
                            when others =>
                                report "Unreachable..." severity failure;
                        end case;
                    end if;

                when rd3 =>
                    if EP_VOUT='1' then
                        hf_vout_happened <= '1';
                        sh_d <= sh_d(23 downto 0) & EP_DOUT;
                    elsif hf_vout_happened='1' then
                        hf_vout_happened <= '0';
                        hfstate <= rd2;
                    end if;
                when rd2 =>
                    if EP_VOUT='1' then
                        hf_vout_happened <= '1';
                        sh_d <= sh_d(23 downto 0) & EP_DOUT;
                    elsif hf_vout_happened='1' then
                        hf_vout_happened <= '0';
                        hfstate <= rd1;
                    end if;
                when rd1 =>
                    if EP_VOUT='1' then
                        hf_vout_happened <= '1';
                        sh_d <= sh_d(23 downto 0) & EP_DOUT;
                    elsif hf_vout_happened='1' then
                        hf_vout_happened <= '0';
                        hfstate <= rd0;
                    end if;
                when rd0 =>
                    if EP_VOUT='1' then
                        hf_vout_happened <= '1';
                        sh_d <= sh_d(23 downto 0) & EP_DOUT;
                    elsif hf_vout_happened='1' then
                        hf_vout_happened <= '0';
                        hfstate <= wbstart;
                    end if;

                when wbstart =>
                    case hf_cmd(3 downto 0) is
                        when x"1" =>
                            wb_write <= '1';
                        when x"2" =>
                            wb_read <= '1';
                        when others =>
                            report "Unreachable..." severity failure;
                    end case;
                    hfstate <= wbwait;

                when wbwait =>
                    wb_write <= '0';
                    wb_read <= '0';
                    if wb_done='1' then
                        case hf_cmd(3 downto 0) is
                            when x"1" =>
                                hfstate <= ret;
                            when x"2" =>
                                sh_d <= wbrddata;
                                hfstate <= sd3;
                            when others =>
                                report "Unreachable..." severity failure;
                        end case;
                    end if;

                when sd3 =>
                    if hf_wr_happened='0' then
                        EP_DIN <= sh_d(31 downto 24);
                        sh_d <= sh_d(23 downto 0) & x"00";
                        EP_WR <='1';
                        hf_wr_happened <= '1';
                    else
                        EP_WR <= '0';
                        if EP_BUSY='0' then
                            hf_wr_happened <= '0';
                            hfstate <= sd2;
                        end if;
                    end if;
                when sd2 =>
                    if hf_wr_happened='0' then
                        EP_DIN <= sh_d(31 downto 24);
                        sh_d <= sh_d(23 downto 0) & x"00";
                        EP_WR <='1';
                        hf_wr_happened <= '1';
                    else
                        EP_WR <= '0';
                        if EP_BUSY='0' then
                            hf_wr_happened <= '0';
                            hfstate <= sd1;
                        end if;
                    end if;
                when sd1 =>
                    if hf_wr_happened='0' then
                        EP_DIN <= sh_d(31 downto 24);
                        sh_d <= sh_d(23 downto 0) & x"00";
                        EP_WR <='1';
                        hf_wr_happened <= '1';
                    else
                        EP_WR <= '0';
                        if EP_BUSY='0' then
                            hf_wr_happened <= '0';
                            hfstate <= sd0;
                        end if;
                    end if;
                when sd0 =>
                    if hf_wr_happened='0' then
                        EP_DIN <= sh_d(31 downto 24);
                        sh_d <= sh_d(23 downto 0) & x"00";
                        EP_WR <='1';
                        hf_wr_happened <= '1';
                    else
                        EP_WR <= '0';
                        if EP_BUSY='0' then
                            hf_wr_happened <= '0';
                            hfstate <= ret;
                        end if;
                    end if;

                when others =>
                    report "Unreachable..." severity failure;
            end case;
        end if;
    end process;

    -- WISHBONE STATE MACHINE
    process(CLK_I, RST_I)
    begin
        if RST_I='1' then
            CYC_O <= '0';
            STB_O <= '0';
            WE_O <= '0';
            DAT_O <= (others=>'0');
            ADR_O <= (others=>'0');
            SEL_O <= (others=>'0');
            wb_done <= '0';
            wbwrrd <= '0';
            wbrddata <= (others => '0');
            hf_failure <= '0';
        elsif rising_edge(CLK_I) then
            case wbstate is

                when idle =>
                    CYC_O <= '0';
                    STB_O <= '0';
                    wb_done <= '0';
                    DAT_O <= (others=>'0');
                    ADR_O <= (others=>'0');
                    SEL_O <= (others=>'0');
                    WE_O <= '0';
                    if wb_write='1' then
                        wbwrrd <= '1';
                        wbstate <= req;
                    elsif wb_read = '1' then
                        wbwrrd <= '0';
                        wbstate <= req;
                    else
                        wbwrrd <= '0';
                    end if;

                when req =>
                    CYC_O <= '1';
                    STB_O <= '1';
                    hf_failure <= '0';
                    if wbwrrd='1' then
                        DAT_O <= sh_d;
                        ADR_O <= sh_a;
                        SEL_O <= (others=>'1');
                        WE_O <= '1';
                    else
                        DAT_O <= (others=>'0');
                        ADR_O <= sh_a;
                        SEL_O <= (others=>'1');
                        WE_O <= '0';
                    end if;
                    if ACK_I='1' then
                        wb_done <= '1';
                        wbstate <= idle;
                        hf_failure <= '0';
                        if wbwrrd='0' then
                            wbrddata <= DAT_I;
                        end if;
                    elsif ERR_I='1' then
                        wb_done <= '1';
                        wbstate <= idle;
                        hf_failure <= '1';
                        if wbwrrd='0' then
                            wbrddata <= DAT_I;
                        end if;
                    elsif STALL_I='0' then
                        wbstate <= waiting;
                    end if;

                when waiting =>
                    CYC_O <= '1';
                    STB_O <= '0';
                    if ACK_I='1' then
                        if wbwrrd='0' then
                            wbrddata <= DAT_I;
                        end if;
                        hf_failure <= '0';
                        wb_done <= '1';
                        wbstate <= idle;
                    elsif ERR_I='1' then
                        wb_done <= '1';
                        wbstate <= idle;
                        hf_failure <= '1';
                        if wbwrrd='0' then
                            wbrddata <= DAT_I;
                        end if;
                    end if;

                when others =>
                    report "Unreachable..." severity failure;
            end case;
        end if;
    end process;

end architecture;
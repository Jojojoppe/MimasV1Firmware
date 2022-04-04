library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity toplevel is
    port (
        ACLK : in std_logic;
        LED  : out std_logic_vector(7 downto 0);
        SW   : in std_logic_vector(3 downto 0);

        SCK : in std_logic;
        SDI : in std_logic;
        SDO : out std_logic
    );
end toplevel;

architecture structural of toplevel is

    -- COMPONENTS
    -- ----------
    component HF_interface is
        port (
            ACLK    : in std_logic;
            ARESETN : in std_logic;

            SCK : in std_logic;
            SDI : in std_logic;
            SDO : out std_logic;

            ep0_dout : out std_logic_vector(7 downto 0);
            ep0_vout : out std_logic;
            ep0_din  : in std_logic_vector(7 downto 0);
            ep0_wr   : in std_logic;
            ep0_busy : out std_logic;
            ep1_dout : out std_logic_vector(7 downto 0);
            ep1_vout : out std_logic;
            ep1_din  : in std_logic_vector(7 downto 0);
            ep1_wr   : in std_logic;
            ep1_busy : out std_logic;

            gp_out : out std_logic_vector(5 downto 0);
            gp_in : in std_logic_vector(5 downto 0)
        );
    end component;

    component hf_2_wb is
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
    end component;

    component wb_reg is
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
    end component;

    -- SIGNALS
    -- -------
    signal ARESETN : std_logic;
    signal ARESET : std_logic;

    -- Debug endpoints
    signal ep0_dout : std_logic_vector(7 downto 0);
    signal ep0_vout : std_logic;
    signal ep0_din  : std_logic_vector(7 downto 0);
    signal ep0_wr   : std_logic;
    signal ep0_busy : std_logic;
    signal ep1_dout : std_logic_vector(7 downto 0);
    signal ep1_vout : std_logic;
    signal ep1_din  : std_logic_vector(7 downto 0);
    signal ep1_wr   : std_logic;
    signal ep1_busy : std_logic;

    signal gp_out : std_logic_vector(5 downto 0);
    signal gp_in : std_logic_vector(5 downto 0);

    -- Wishbone bus
    signal ADR_O : std_logic_vector(31 downto 0);
    signal DAT_O : std_logic_vector(31 downto 0);
    signal DAT_I : std_logic_vector(31 downto 0);
    signal WE_O : std_logic;
    signal SEL_O : std_logic_vector(3 downto 0);
    signal STB_O : std_logic;
    signal ACK_I : std_logic;
    signal CYC_O : std_logic;
    signal STALL_I : std_logic;

    signal reg_output : std_logic_vector(31 downto 0);

begin

    ARESETN <= SW(0);
    ARESET <= not ARESETN;

    LED <= reg_output(7 downto 0);

    cHF_interface : component HF_interface port map(
        ACLK => ACLK, ARESETN => ARESETN, SCK => SCK, SDI => SDI, SDO => SDO,
        ep0_dout => ep0_dout, ep1_dout => ep1_dout,
        ep0_vout => ep0_vout, ep1_vout => ep1_vout,
        ep0_din => ep0_din, ep1_din => ep1_din,
        ep0_wr => ep0_wr, ep1_wr => ep1_wr,
        ep0_busy => ep0_busy, ep1_busy => ep1_busy,
        gp_out => gp_out, gp_in => gp_in
    );

    gp_in <= "00" & SW;

    ep1_din <= (others=>'0');
    ep1_wr <= '0';

    chf_2_wb : component hf_2_wb port map(
        CLK_I => ACLK, RST_I => ARESET,
        ADR_O => ADR_O, DAT_O => DAT_O, DAT_I => DAT_I,
        WE_O => WE_O, SEL_O => SEL_O, STB_O => STB_O,
        ACK_I => ACK_I, CYC_O => CYC_O, STALL_I => STALL_I,
        EP_DOUT => ep0_dout, EP_VOUT => ep0_vout,
        EP_DIN => ep0_din, EP_WR => ep0_wr, EP_BUSY => ep0_busy
    );

    cwb_reg : component wb_reg port map(
        CLK_I => ACLK, RST_I => ARESET,
        ADR_I => ADR_O(0 downto 0), DAT_I => DAT_O, DAT_O => DAT_I,
        WE_I => WE_O, SEL_I => SEL_O, STB_I => STB_O,
        ACK_O => ACK_I, CYC_I => CYC_O, STALL_O => STALL_I,
        reg_output => reg_output
    );

end architecture;
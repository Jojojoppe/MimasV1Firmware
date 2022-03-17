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
            ep1_dout : out std_logic_vector(7 downto 0);
            ep1_vout : out std_logic;
            ep1_din  : in std_logic_vector(7 downto 0);
            ep1_wr   : in std_logic;

            gp_out : out std_logic_vector(5 downto 0);
            gp_in : in std_logic_vector(5 downto 0)
        );
    end component;

    -- SIGNALS
    -- -------
    signal ARESETN : std_logic;

    -- Debug endpoints
    signal ep0_dout : std_logic_vector(7 downto 0);
    signal ep0_vout : std_logic;
    signal ep0_din  : std_logic_vector(7 downto 0);
    signal ep0_wr   : std_logic;
    signal ep1_dout : std_logic_vector(7 downto 0);
    signal ep1_vout : std_logic;
    signal ep1_din  : std_logic_vector(7 downto 0);
    signal ep1_wr   : std_logic;

    signal gp_out : std_logic_vector(5 downto 0);
    signal gp_in : std_logic_vector(5 downto 0);
begin

    ARESETN <= SW(0);

    LED <= "00" & gp_out;

    cHF_interface : component HF_interface port map(
        ACLK => ACLK, ARESETN => ARESETN, SCK => SCK, SDI => SDI, SDO => SDO,
        ep0_dout => ep0_dout, ep1_dout => ep1_dout,
        ep0_vout => ep0_vout, ep1_vout => ep1_vout,
        ep0_din => ep0_din, ep1_din => ep1_din,
        ep0_wr => ep0_wr, ep1_wr => ep1_wr,
        gp_out => gp_out, gp_in => gp_in
    );

    gp_in <= "00" & SW;

    -- Echo
    process (ACLK, ARESETN)
    begin
        if ARESETN = '0' then
            ep0_din <= x"00";
            ep0_wr  <= '0';
            ep1_din <= x"00";
            ep1_wr  <= '0';
        elsif rising_edge(ACLK) then
            if ep0_vout = '1' then
                ep0_din <= ep0_dout;--std_logic_vector(unsigned(ep0_dout)+1);
                ep0_wr  <= '1';
            else
                ep0_wr <= '0';
            end if;
            if ep1_vout = '1' then
                ep1_din <= ep1_dout;
                ep1_wr  <= '1';
            else
                ep1_wr <= '0';
            end if;
        end if;
    end process;

end architecture;
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity HF_interface is
    port (
        ACLK    : in std_logic;
        ARESETN : in std_logic;

        SCK : in std_logic;
        SDI : in std_logic;
        SDO : out std_logic;

        ep0_dout : out std_logic_vector(7 downto 0);
        ep0_vout : out std_logic;
        ep0_din : in std_logic_vector(7 downto 0);
        ep0_wr : in std_logic;
        ep1_dout : out std_logic_vector(7 downto 0);
        ep1_vout : out std_logic;
        ep1_din : in std_logic_vector(7 downto 0);
        ep1_wr : in std_logic;

        gp_out : out std_logic_vector(5 downto 0);
        gp_in : in std_logic_vector(5 downto 0)
    );
    attribute keep_hierarchy : string;
    attribute keep_hierarchy of HF_interface : entity is "yes";
end entity;

architecture structural of HF_interface is

    -- COMPONENTS
    -- ----------
    component input_sync is
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
    end component;

    -- SIGNALS
    -- -------

    signal i_SCK, i_SDI   : std_logic;
    signal pe_SCK, pe_SDI : std_logic;
    signal ne_SCK, ne_SDI : std_logic;

    -- Shift registers
    signal sr_status, sr_ep0, sr_ep1 : std_logic_vector(7 downto 0);
    -- Shift counter
    signal count : unsigned(7 downto 0);
    signal done : std_logic;
    signal busy : std_logic;

    -- Data registers
    signal d_ep0_in : std_logic_vector(7 downto 0);
    signal d_ep1_in : std_logic_vector(7 downto 0);
    signal d_gpo : std_logic_vector(5 downto 0);

    signal d_ep0_invalid : std_logic;
    signal d_ep1_invalid : std_logic;

begin

    -- Input signal clock conversion
    ccSCK : component input_sync port map(
        ACLK => ACLK, ARESETN => ARESETN, i => SCK, o => i_SCK, pe => pe_SCK, ne => ne_SCK
    );
    ccSDI : component input_sync port map(
        ACLK => ACLK, ARESETN => ARESETN, i => SDI, o => i_SDI, pe => pe_SDI, ne => ne_SDI
    );

    -- SPI transmission at active to idle
    -- CLOCK idle at low
    -- sampled at middle data output time

    -- Shift registers
    SDO <= sr_status(7);
    process(ACLK, ARESETN)
    begin
        if ARESETN='0' then
            sr_status <= (others=>'0');
            sr_ep0 <= (others=>'0');
            sr_ep1 <= (others=>'0');
        elsif rising_edge(ACLK) then
            if ne_SCK='1' then
                sr_ep1 <= sr_ep1(6 downto 0) & i_SDI;
                sr_ep0 <= sr_ep0(6 downto 0) & sr_ep1(7);
                sr_status <= sr_status(6 downto 0) & sr_ep0(7);
            elsif done='1' then
                sr_status <= (others => '0');
                sr_ep0 <= (others => '0');
                sr_ep1 <= (others => '0');
            elsif busy='0' then
                if ep0_wr='1' then
                    sr_status(0) <= '1';
                    sr_ep0 <= ep0_din;
                end if;
                if ep1_wr='1' then
                    sr_status(1) <= '1';
                    sr_ep1 <= ep1_din;
                end if;
            elsif count=0 then
                sr_status(7 downto 2) <= gp_in;
            end if;
        end if;
    end process;

    -- Counter
    process(ACLK, ARESETN)
    begin
        if ARESETN='0' then
            count <= (others=>'0');
            done <= '0';
        elsif rising_edge(ACLK) then
            if ne_SCK='1' and count<24 then
                count <= count+1;
                done <= '0';
            elsif count<24 then
                done <= '0';
            else
                count <= (others=>'0');
                done <= '1';
            end if;
        end if;
    end process;

    -- Done signal
    process(ACLK, ARESETN)
    begin
        if ARESETN='0' then
            busy <= '0';
        elsif rising_edge(ACLK) then
            if pe_SCK='1' and count=0 then
                busy <= '1';
            elsif done='1' then
                busy <= '0';
            end if;
        end if;
    end process;

    -- Loading of data in registers
    process(ACLK, ARESETN)
    begin
        if ARESETN='0' then
            d_ep0_in <= (others => '0'); 
            d_ep1_in <= (others => '0'); 
            d_ep0_invalid <= '0';
            d_ep1_invalid <= '0';
            d_gpo <= (others => '0');
        elsif rising_edge(ACLK) then
            if sr_status(0)='1' and done='1' then
                d_ep0_in <= sr_ep0;
                d_ep0_invalid <= '1';
            else
                d_ep0_invalid <= '0';
            end if;
            if sr_status(1)='1' and done='1' then
                d_ep1_in <= sr_ep1;
                d_ep1_invalid <= '1';
            else
                d_ep1_invalid <= '0';
            end if;
            if done='1' then
                d_gpo <= sr_status(7 downto 2);
            end if;
        end if;
    end process;

    -- Endpoint IO
    ep0_dout <= d_ep0_in;
    ep1_dout <= d_ep1_in;
    ep0_vout <= d_ep0_invalid;
    ep1_vout <= d_ep1_invalid;
    gp_out <= d_gpo;

end architecture;
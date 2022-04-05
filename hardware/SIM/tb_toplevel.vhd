library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity tb_toplevel is
end entity;

architecture behavioural of tb_toplevel is

    -- COMPONENTS
    -- ----------
    component toplevel is
        port (
            ACLK    : in std_logic;
            LED : out std_logic_vector(7 downto 0);
            SW : in std_logic_vector(3 downto 0);

            SCK : in std_logic;
            SDI : in std_logic;
            SDO : out std_logic
        );
    end component;

    -- SIGNALS
    -- -------
    signal ACLK    : std_logic := '0';
    signal ARESETN : std_logic := '0';
    signal LED : std_logic_vector(7 downto 0) := "00000000";

    signal SCK, SDI, SDO : std_logic := '0';
    signal CS : std_logic := '1';

    -- PROCEDURE
    -- ---------
    procedure SPI_TRANSFER(
        signal SCK : out std_logic;
        signal SDI : out std_logic;
        signal SDO : in std_logic;
        signal CS : out std_logic;
        variable d : inout std_logic_vector
    ) is
        constant SPI_PERIOD : time := 350 ns;
    begin

        -- report "Sending " & integer'image(to_integer(unsigned(d)));
        for i in 0 to 7 loop
            SDI <= d(7);
            SCK <= '1';
            wait for SPI_PERIOD/2;
            SCK <= '0';
            d := d(6 downto 0) & SDO;
            wait for SPI_PERIOD/2;
        end loop;
        SCK <= '0';
        SDI <= '0';
        -- report "Received " & integer'image(to_integer(unsigned(d)));
    end procedure;

    procedure SPI_EP0_WR(
        signal SCK : out std_logic;
        signal SDI : out std_logic;
        signal SDO : in std_logic;
        signal CS : out std_logic;
        variable addr : in std_logic_vector;
        variable data : in std_logic_vector;
        variable resp : inout std_logic_vector
    ) is
        variable d : std_logic_vector(7 downto 0);
        variable cnt : integer;
        constant SPI_PERIOD : time := 350 ns;
    begin
        report "Sending " & integer'image(to_integer(unsigned(data))) & " to address " & integer'image(to_integer(unsigned(addr)));
        CS <= '0';
        wait for SPI_PERIOD*2;

        d := "00000001";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"01";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"00";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        
        d := "00000001";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := addr(31 downto 24);
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"00";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := "00000001";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := addr(23 downto 16);
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"00";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := "00000001";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := addr(15 downto 8);
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"00";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := "00000001";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := addr(7 downto 0);
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"00";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);

        d := "00000001";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := data(31 downto 24);
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"00";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := "00000001";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := data(23 downto 16);
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"00";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := "00000001";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := data(15 downto 8);
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"00";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := "00000001";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := data(7 downto 0);
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"00";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);

        cnt := 32;
        while cnt>0 loop

            d := "00000000";
            SPI_TRANSFER(SCK, SDI, SDO, CS, d);
            resp := "00000000";
            SPI_TRANSFER(SCK, SDI, SDO, CS, resp);
            d := "00000000";
            SPI_TRANSFER(SCK, SDI, SDO, CS, d);

            if not(resp=x"00") then
                exit;
            end if;

            cnt := cnt - 1;
        end loop;
        if cnt=0 then
            report "SPI EP0 Write timeout..." severity failure;
        else
            report "Response " & integer'image(to_integer(unsigned(resp)));
        end if;

        CS <= '1';
        wait for SPI_PERIOD*2;

    end procedure;

    procedure SPI_EP0_RD(
        signal SCK : out std_logic;
        signal SDI : out std_logic;
        signal SDO : in std_logic;
        signal CS : out std_logic;
        variable addr : in std_logic_vector;
        variable data : out std_logic_vector;
        variable resp : inout std_logic_vector
    ) is
        variable d : std_logic_vector(7 downto 0);
        variable cnt : integer;
        constant SPI_PERIOD : time := 350 ns;
    begin
        report "Reading " & " from address " & integer'image(to_integer(unsigned(addr)));
        CS <= '0';
        wait for SPI_PERIOD*2;

        d := "00000001";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"02";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"00";

        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := "00000001";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := addr(31 downto 24);
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"00";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := "00000001";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := addr(23 downto 16);
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"00";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := "00000001";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := addr(15 downto 8);
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"00";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := "00000001";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := addr(7 downto 0);
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);
        d := x"00";
        SPI_TRANSFER(SCK, SDI, SDO, CS, d);

        cnt := 32;
        while cnt>0 loop

            d := "00000000";
            SPI_TRANSFER(SCK, SDI, SDO, CS, d);
            resp := "00000000";
            SPI_TRANSFER(SCK, SDI, SDO, CS, resp);
            d := "00000000";
            SPI_TRANSFER(SCK, SDI, SDO, CS, d);

            if not(resp=x"00") then
                exit;
            end if;

            cnt := cnt - 1;
        end loop;
        if cnt=0 then
            report "SPI EP0 Write timeout..." severity failure;
        else
            report "Response " & integer'image(to_integer(unsigned(resp)));
        end if;

        CS <= '1';
        wait for SPI_PERIOD*2;

    end procedure;

begin

    ACLK <= not ACLK after 10 ns;

    process
        variable resp : std_logic_vector(7 downto 0);
        variable data : std_logic_vector(31 downto 0);
        variable addr : std_logic_vector(31 downto 0);
    begin
        ARESETN <= '0';
        wait for 50 ns;
        ARESETN <= '1';
        wait for 20 ns;

        data := x"deadbeef";
        addr := x"12345678";
        SPI_EP0_WR(SCK, SDI, SDO, CS, addr, data, resp);

        data := x"ffffffff";
        addr := x"00000020";
        SPI_EP0_RD(SCK, SDI, SDO, CS, addr, data, resp);

        wait for 10 us;
        report "END OF SIMULATION" severity failure;
    end process;

    dut : component toplevel port map(
        ACLK => ACLK,
        LED => LED,
        SW => ARESETN & ARESETN & ARESETN & ARESETN,
        SCK => SCK, SDI => SDI, SDO => SDO
    );

end architecture;
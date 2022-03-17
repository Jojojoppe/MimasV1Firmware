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

    signal SCK, SDI, SDO : std_logic := '0';

    -- PROCEDURE
    -- ---------
    procedure SPI_TRANSFER(
        signal SCK : out std_logic;
        signal SDI : out std_logic;
        signal SDO : in std_logic;
        variable d : inout std_logic_vector
    ) is
        constant SPI_PERIOD : time := 283 ns;
    begin
        report "Sending " & integer'image(to_integer(unsigned(d)));
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
        report "Received " & integer'image(to_integer(unsigned(d)));
    end procedure;

begin

    ACLK <= not ACLK after 10 ns;

    process
        variable d : std_logic_vector(7 downto 0);
    begin
        ARESETN <= '0';
        wait for 50 ns;
        ARESETN <= '1';
        wait for 20 ns;

        d := "10100011";
        SPI_TRANSFER(SCK, SDI, SDO, d);
        d := x"01";
        SPI_TRANSFER(SCK, SDI, SDO, d);
        d := x"EF";
        SPI_TRANSFER(SCK, SDI, SDO, d);

        wait for 850 ns;

        d := "01000010";
        SPI_TRANSFER(SCK, SDI, SDO, d);
        d := x"AB";
        SPI_TRANSFER(SCK, SDI, SDO, d);
        d := x"CD";
        SPI_TRANSFER(SCK, SDI, SDO, d);

        wait for 850 ns;

        d := "11111100";
        SPI_TRANSFER(SCK, SDI, SDO, d);
        d := x"00";
        SPI_TRANSFER(SCK, SDI, SDO, d);
        d := x"00";
        SPI_TRANSFER(SCK, SDI, SDO, d);

        wait for 20 ns;
        report "END OF SIMULATION" severity failure;
    end process;

    dut : component toplevel port map(
        ACLK => ACLK,
        LED => open,
        SW => ARESETN & ARESETN & ARESETN & ARESETN,
        SCK => SCK, SDI => SDI, SDO => SDO
    );

end architecture;
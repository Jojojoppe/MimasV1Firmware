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
            SDO : out std_logic;
            HFRST : in std_logic
        );
    end component;

    -- SIGNALS
    -- -------
    signal ACLK    : std_logic := '0';
    signal ARESETN : std_logic := '0';
    signal LED : std_logic_vector(7 downto 0) := "00000000";

    signal SCK, SDI, SDO : std_logic := '0';
    signal CS : std_logic := '1';

    -- PROCEDURES
    -- ----------
    procedure SPI_TRANSFER(
        signal SCK : out std_logic;
        signal SDI : out std_logic;
        signal SDO : in std_logic;
        variable d : inout std_logic_vector
    ) is
        constant SPI_PERIOD : time := 350 ns;
    begin
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
        wait for SPI_PERIOD;
    end procedure;

    procedure HF_TRANSFER(
        signal SCK : out std_logic;
        signal SDI : out std_logic;
        signal SDO : in std_logic;
        signal CS : out std_logic;
        variable status : inout std_logic_vector;
        variable ep0 : inout std_logic_vector;
        variable ep1 : inout std_logic_vector 
    ) is
        constant HF_HOLDOFF : time := 500 ns;
    begin
        wait for HF_HOLDOFF;
        CS <= '0';
        wait for HF_HOLDOFF;

        SPI_TRANSFER(SCK, SDI, SDO, status);
        wait for HF_HOLDOFF;
        SPI_TRANSFER(SCK, SDI, SDO, ep0);
        wait for HF_HOLDOFF;
        SPI_TRANSFER(SCK, SDI, SDO, ep1);

        wait for HF_HOLDOFF;
        CS <= '1';
        wait for HF_HOLDOFF;
    end procedure;

begin

    ACLK <= not ACLK after 10 ns;

    process
        variable status : std_logic_vector(7 downto 0);
        variable ep0 : std_logic_vector(7 downto 0);
        variable ep1 : std_logic_vector(7 downto 0);
    begin
        ARESETN <= '0';
        wait for 50 ns;
        ARESETN <= '1';
        wait for 20 ns;
    
        -- Reset WB tree
        status := "00000100";
        ep0 := x"00";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
        status := "00000000";
        ep0 := x"00";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);

        -- NOP command
        status := "00000001";
        ep0 := x"00";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
            -- get RET
        status := "00000000";
        ep0 := x"00";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);

        -- WRITE command
        status := "00000001";
        ep0 := x"01";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
            -- send address
        status := "00000001";
        ep0 := x"12";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
        status := "00000001";
        ep0 := x"34";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
        status := "00000001";
        ep0 := x"56";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
        status := "00000001";
        ep0 := x"78";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
            -- send data
        status := "00000001";
        ep0 := x"de";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
        status := "00000001";
        ep0 := x"ad";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
        status := "00000001";
        ep0 := x"be";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
        status := "00000001";
        ep0 := x"ef";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
            -- get RET
        status := "00000000";
        ep0 := x"00";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);

        -- READ command
        status := "00000001";
        ep0 := x"02";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
            -- send address
        status := "00000001";
        ep0 := x"fe";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
        status := "00000001";
        ep0 := x"dc";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
        status := "00000001";
        ep0 := x"ba";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
        status := "00000001";
        ep0 := x"98";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
            -- get data
        status := "00000000";
        ep0 := x"00";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
        status := "00000000";
        ep0 := x"00";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
        status := "00000000";
        ep0 := x"00";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
        status := "00000000";
        ep0 := x"00";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);
            -- get RET
        status := "00000000";
        ep0 := x"00";
        ep1 := x"00";
        HF_TRANSFER(SCK, SDI, SDO, CS, status, ep0, ep1);

        wait for 10 us;
        report "END OF SIMULATION" severity failure;
    end process;

    dut : component toplevel port map(
        ACLK => ACLK,
        HFRST => not ARESETN,
        LED => LED,
        SW => x"0",
        SCK => SCK, SDI => SDI, SDO => SDO
    );

end architecture;
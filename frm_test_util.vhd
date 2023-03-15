library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;

Package frm_test_util is  
    
  type otn_overhead_type is
    record
      frm_nr       :  std_logic_vector(31 downto 0);
      row          :  integer range 4 downto 0;
      col          :  integer range 128 downto 0;
      data         :  std_logic_vector(255 downto 0);
      fas_pos      :  integer range 511 downto 0;-- start med 511
      
 
      FAS          :  std_logic_vector(47 downto 0);--x"f6f6f6282828"
      MFAS         :  std_logic_vector(7 downto 0);---dldasd
      SM_TTI       :  std_logic_vector(511 downto 0);
      SM_BIP8      :  std_logic_vector(7 downto 0);
      SM_AUX       :  std_logic_vector(7 downto 0);
      GCC0         :  std_logic_vector(15 downto 0);
      OTU3_RES     :  std_logic_vector(15 downto 0);
      OPU3_RES1    :  std_logic_vector(7 downto 0);
      OPU3_JC1     :  std_logic_vector(7 downto 0);
      
      ODU3_RES1    :  std_logic_vector(23 downto 0);
      TCM_ACT      :  std_logic_vector(7 downto 0);

      TCM6_TTI     :  std_logic_vector(511 downto 0);
      TCM6_BIP8    :  std_logic_vector(7 downto 0);
      TCM6_AUX     :  std_logic_vector(7 downto 0);
              
      TCM5_TTI     :  std_logic_vector(511 downto 0);
      TCM5_BIP8    :  std_logic_vector(7 downto 0);
      TCM5_AUX     :  std_logic_vector(7 downto 0);
              
      TCM4_TTI     :  std_logic_vector(511 downto 0);
      TCM4_BIP8    :  std_logic_vector(7 downto 0);
      TCM4_AUX     :  std_logic_vector(7 downto 0);
              
      FTFL         :  std_logic_vector(7 downto 0);

      OPU3_RES2    :  std_logic_vector(7 downto 0);
      OPU3_JC2     :  std_logic_vector(7 downto 0);

      TCM3_TTI     :  std_logic_vector(511 downto 0);
      TCM3_BIP8    :  std_logic_vector(7 downto 0);
      TCM3_AUX     :  std_logic_vector(7 downto 0);
              
      TCM2_TTI     :  std_logic_vector(511 downto 0);
      TCM2_BIP8    :  std_logic_vector(7 downto 0);
      TCM2_AUX     :  std_logic_vector(7 downto 0);
              
      TCM1_TTI     :  std_logic_vector(511 downto 0);
      TCM1_BIP8    :  std_logic_vector(7 downto 0);
      TCM1_AUX     :  std_logic_vector(7 downto 0);
                
      PM_TTI       :  std_logic_vector(511 downto 0);
      PM_BIP8      :  std_logic_vector(7 downto 0);
      PM_AUX       :  std_logic_vector(7 downto 0);
                         
      EXP          :  std_logic_vector(15 downto 0);

      OPU3_RES3    :  std_logic_vector(7 downto 0);
      OPU3_JC3     :  std_logic_vector(7 downto 0);
 
      GCC1         :  std_logic_vector(15 downto 0);
      GCC2         :  std_logic_vector(15 downto 0);
              
      APS          :  std_logic_vector(31 downto 0);
      ODU3_RES2    :  std_logic_vector(47 downto 0);
              
      PT           :  std_logic_vector(7 downto 0);
      vcPT         :  std_logic_vector(7 downto 0);
      
      STM_A1       :  std_logic_vector(7 downto 0);
      STM_A2       :  std_logic_vector(7 downto 0);
      
      STM_BIP8     :  std_logic_vector(7 downto 0);
      STM_J0       :  std_logic_vector(7 downto 0);
      STM_J0_SEQ   :  std_logic_vector(511 downto 0);
      
      jc_seq       :  std_logic_vector(31 downto 0);
      
      demap        :  std_logic_vector(7 downto 0);
      demap_stm    :  std_logic_vector(7 downto 0);
      
      otu3ais      :  std_logic_vector(7 downto 0);
      odu3ais      :  std_logic_vector(7 downto 0);
      odu3oci      :  std_logic_vector(7 downto 0);
      odu3lck      :  std_logic_vector(7 downto 0);
                 
      cbr_ais      :  std_logic_vector(7 downto 0);

    end record;  

  type gen_stat_type is
    record
      frm_nr       :  std_logic_vector(31 downto 0);
      stm_frm_nr   :  std_logic_vector(31 downto 0);
      MFAS         :  std_logic_vector(7 downto 0);
    end record;
    
  type test_config_type is
    record
      conf             :  std_logic_vector(1 downto 0); --OTN, SDH, CBR
      cbr_map          :  std_logic;
      prbs             :  std_logic;
      clk_mode         :  integer;
      disable_gen      :  std_logic;
      disable_ana      :  std_logic;
      otn_scr_inh_gen  :  std_logic;
      otn_scr_inh_ana  :  std_logic; 
      txt              :  string(1 to 2);
    end record;
  
  

procedure otn_scramble(
  pos              :  in      integer range 511 downto 0;
  inh              :  in      std_logic;
  scr_reg          :  inout   std_logic_vector(15 downto 0);
  reset            :  in      std_logic;
  data             :  inout   std_logic_vector(511 downto 0));   
  

  
procedure otn_bip8(
  pos              :  in      integer range 511 downto 0;
  bip8             :  inout   std_logic_vector(7 downto 0);
  mask             :  in      std_logic_vector(31 downto 0);
  data             :  in      std_logic_vector(511 downto 0));  

  
  
procedure prbs31(
  prbs_reg        :  inout   std_logic_vector(30 downto 0);
  mask            :  in      std_logic_vector(31 downto 0);
  prbs_out        :  out     std_logic_vector(255 downto 0));


procedure odu_ais(
  pos              :  in      integer range 511 downto 0;
  mode             :  in      std_logic;
  mask             :  in      std_logic_vector(31 downto 0);
  data             :  inout   std_logic_vector(511 downto 0);
  ais              :  inout   std_logic;
  oci              :  inout   std_logic;
  lck              :  inout   std_logic);


end frm_test_util;


  
package body frm_test_util is

-- scrambler
procedure otn_scramble(
  pos              :  in      integer range 511 downto 0;
  inh              :  in      std_logic;
  scr_reg          :  inout   std_logic_vector(15 downto 0);
  reset            :  in      std_logic;
  data             :  inout   std_logic_vector(511 downto 0)) is
  
  variable scr0 : std_logic;
  variable start_pos : integer;

begin
  
  if (inh = '0') then
  
    if (reset = '1') then
      start_pos := pos - 8*6;
    else
      start_pos := pos;
    end if;
    
    for i in start_pos downto (pos-256+1)loop
      
      if (i = start_pos and reset = '1')  then
        scr_reg := X"FFFF";
      else
        scr0 := scr_reg(0) xor scr_reg(2) xor scr_reg(11) xor scr_reg(15);
        for n in 15 downto 1 loop
          scr_reg(n) := scr_reg(n-1);
        end loop;
        scr_reg(0) := scr0;
      end if;    
    
      data(i) := data(i) xor scr_reg(15);
      
    end loop;
    
  end if; --inh
  
end;

--bip8
procedure otn_bip8(
  pos              :  in      integer range 511 downto 0;
  bip8             :  inout   std_logic_vector(7 downto 0);
  mask             :  in      std_logic_vector(31 downto 0);
  data             :  in      std_logic_vector(511 downto 0)) is
  
begin
  
  for i in 31 downto 0 loop
    if mask(i) = '1' then
      bip8 := bip8 xor data(pos+(i-31)*8 downto pos+(i-31)*8-8+1);
    end if;
  end loop;

end;


procedure prbs31(
  prbs_reg        :  inout   std_logic_vector(30 downto 0);
  mask            :  in      std_logic_vector(31 downto 0);
  prbs_out        :  out     std_logic_vector(255 downto 0)) is

variable   prbs0  :  std_logic;

begin
  
  for i in 31 downto 0 loop
    if mask(i) = '1' then
      for j in 7 downto 0 loop

        prbs_out(i*8+j) := prbs_reg(30);

        prbs0 := prbs_reg(27) xor prbs_reg(30);
        for n in 30 downto 1 loop
          prbs_reg(n) := prbs_reg(n-1);
        end loop;
        prbs_reg(0) := prbs0;

      end loop;
    end if;
  end loop;

end;




procedure odu_ais(
  pos              :  in      integer range 511 downto 0;
  mode             :  in      std_logic;
  mask             :  in      std_logic_vector(31 downto 0);
  data             :  inout   std_logic_vector(511 downto 0);
  ais              :  inout   std_logic;
  oci              :  inout   std_logic;
  lck              :  inout   std_logic) is


begin
  
  for i in 31 downto 0 loop
    if mask(i) = '1' then

      if (mode = '1') then -- alarm detection
      
        if data(pos+(i-31)*8 downto pos+(i-31)*8-8+1) /= X"FF" then
          ais := '0';
        end if; 
        
        if data(pos+(i-31)*8 downto pos+(i-31)*8-8+1) /= X"66" then
          oci := '0';
        end if; 
        
        if data(pos+(i-31)*8 downto pos+(i-31)*8-8+1) /= X"55" then
          lck := '0';
        end if;
      
      else  --mode = 0  Alarm generation
       
        if (ais = '1') then
          data(pos+(i-31)*8 downto pos+(i-31)*8-8+1) := X"FF";
        end if;
        
        if (oci = '1') then
          data(pos+(i-31)*8 downto pos+(i-31)*8-8+1) := X"66";
        end if;
        
        if (lck = '1') then
          data(pos+(i-31)*8 downto pos+(i-31)*8-8+1) := X"55";
        end if;
        
      end if; --mode
    end if;  --mask
  end loop;
end;



end package body frm_test_util;  

let reg_nb = 16
let pc = ref 0
let regs = Array.make reg_nb 0
let reg_i = 0

let fetch () =
  pc := !pc + 1;
  Memory.get (!pc - 1)

let and_nb nb1 nb2 =
  if (nb1 = 0) || (nb2 = 0) then
    0
  else
    1

let or_nb nb1 nb2 =
  if (nb1 <> 0) || (nb2 <> 0) then
    1
  else
    0

let xor_nb nb1 nb2 =
  if (nb1 = 0) && (nb2 <> 0) then
    1
  else if (nb1 <> 0) && (nb2 = 0) then
    1
  else
    0

let execute instr =
  match instr with
  (* 0x00E0 Screen cleaning *)
  | 0x00E0 -> Screen.clear ()
  (* 0x00EE Subroutine return *)
  | 0x00EE -> ()
  (* 0x1NNN Jump on NNN*)
  | ins when (ins land 0xF000) = 0x1000 -> pc := ins land 0x0FFF
  (* 0x2NNN Calls subroutine at 0xNNN *)
  (* TODO *)
  (* 0x3XKK Goes next instr if VX == KK *)
  | ins when (ins land 0xF000) = 0x3000 ->
    let sub reg value =
      if (Array.get regs reg) = value then
        pc := !pc + 1
    in
      sub ((ins land 0x0F00) / 0x0100) (ins land 0x00FF)
  (* 0x4XKK Goes next if VX <> KK *)
  | ins when (ins land 0xF000) = 0x4000 ->
    let sub reg value =
      if (Array.get regs reg) <> value then
        pc := !pc + 1
    in
      sub ((ins land 0x0F00) / 0x0100) (ins land 0x00FF)
  (* 0x5XY0 Goes next if VX == VY *)
  | ins when (ins land 0xF000) = 0x5000 ->
    let sub reg1 reg2 =
      if (Array.get regs reg1) = (Array.get regs reg2) then
        pc := !pc + 1
    in
      sub ((ins land 0x0F00) / 0x0100) ((ins land 0x00F0) / 0x0010)
  (* 0x6XKK Load KK in VX *)
  | ins when (ins land 0xF000) = 0x6000 ->
    let sub reg value =
      Array.set regs reg value
    in
      sub ((ins land 0x0F00) / 0x0100) ((ins land 0x00FF))
  (* 0x7XKK Load VX + KK in VX *)
  | ins when (ins land 0xF000) = 0x7000 ->
    let sub reg value =
      Array.set regs reg ((Array.get regs reg) + value);
      Array.set regs reg (0xFF land (Array.get regs reg))
    in
      sub ((ins land 0x0F00) / 0x0100) ((ins land 0x00FF))
  (* 0x8XY0 Loads VY in VX *)
  | ins when (ins land 0xF00F) = 0x8000 ->
    let sub reg1 reg2 =
      Array.set regs reg1 (Array.get regs reg2)
    in
      sub ((ins land 0x0F00) / 0x0100) ((ins land 0x00F0) / 0x0010)
  (* 0x8XY1 Loads VX || VY *)
  | ins when (ins land 0xF00F) = 0x8001 ->
    let sub reg1 reg2 =
      Array.set regs reg1 (or_nb (Array.get regs reg1) (Array.get regs reg2))
    in
      sub ((ins land 0x0F00) / 0x0100) ((ins land 0x00F0) / 0x0010)
  (* 0x8XY3 Loads VX ^ VY *)
  | ins when (ins land 0xF00F) = 0x8003 ->
    let sub reg1 reg2 =
      Array.set regs reg1 (xor_nb (Array.get regs reg1) (Array.get regs reg2))
    in
      sub ((ins land 0x0F00) / 0x0100) ((ins land 0x00F0) / 0x0010)
  (* 0x8XY4 Loads VX + VY in VX; VF set to 1 if overflow, 0 otherwise*)
  | ins when (ins land 0xF00F) = 0x8004 ->
    let sub reg1 reg2 =
      Array.set regs reg1 ((Array.get regs reg1) + (Array.get regs reg2));
      (if (Array.get regs reg1) > 0xFF then
        Array.set regs 0xF 1
      else
        Array.set regs 0xF 0);
      Array.set regs reg1 ((Array.get regs reg1) land 0xFF)
    in
      sub ((ins land 0x0F00) / 0x0100) ((ins land 0x00F0) / 0x0010)
  (* 0x8XY5 Load VX - VY in VX; VF set to 1 if VY > VX, 0 otherwise *)
  | ins when (ins land 0xF00F) = 0x8005 ->
    let sub reg1 reg2 =
      (if (Array.get regs reg1) < (Array.get regs reg2) then
        Array.set regs 0xF 1
      else
        Array.set regs 0xF 0);
      Array.set regs reg1 ((Array.get regs reg1) - (Array.get regs reg2))
    in
      sub ((ins land 0x0F00) / 0x0100) ((ins land 0x00F0) / 0x0010)
  (* 0x8XY6 Right shift on VX; puts output bit in VF *)
  | ins when (ins land 0xF00F) = 0x8006 ->
    let sub reg1 =
      Array.set regs 0xF ((Array.get regs reg1) mod 2);
      Array.set regs reg1 ((Array.get regs reg1) / 2)
    in
      sub ((ins land 0x0F00) / 0x0100)
  (* 0x8XY7 Loads VY - VX in VX; VF set to 1 if VX > VY, 0 otherwise *)
  | ins when (ins land 0xF00F) = 0x8007 ->
    let sub reg1 reg2 =
      (if (Array.get regs reg1) > (Array.get regs reg2) then
        Array.set regs 0xF 1
      else
        Array.set regs 0xF 0);
      Array.set regs reg1 ((Array.get regs reg2) - (Array.get regs reg1))
    in
      sub ((ins land 0x0F00) / 0x0100) ((ins land 0x00F0) / 0x0010)
  (* 0x8XYE Left shift on VX; puts output bit in VF *)
  | ins when (ins land 0xF00F) = 0x800E ->
    let sub reg1 =
      Array.set regs 0xF (((Array.get regs reg1) * 2) / 0x100);
      Array.set regs reg1 ((Array.get regs reg1) * 2);
      Array.set regs reg1 ((Array.get regs reg1) land 0xFF)
    in
      sub ((ins land 0x0F00) / 0x0100)
  (* 0x9XY0 Goes next instruction if VX <> VY *)
  | ins when (ins land 0xF000) = 0x9000 ->
    let sub reg1 reg2 =
      if (Array.get regs reg1) <> (Array.get regs reg2) then
        pc := !pc + 1
    in
      sub ((ins land 0x0F00) / 0x0100) ((ins land 0x00F0) / 0x0010)
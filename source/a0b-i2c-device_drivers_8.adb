--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

pragma Ada_2022;

package body A0B.I2C.Device_Drivers_8 is

   procedure Reset_State (Self : in out I2C_Device_Driver'Class);
   --  Resets state of the driver.

   procedure Fill_Address_Buffer
     (Self    : in out I2C_Device_Driver'Class;
      Address : Register_Address);
   --  Fill address buffer and link it to first entry of write buffer
   --  descriptor.

   -------------------------
   -- Fill_Address_Buffer --
   -------------------------

   procedure Fill_Address_Buffer
     (Self    : in out I2C_Device_Driver'Class;
      Address : Register_Address) is
   begin
      Self.Address_Buffer (0) := Address;

      Self.Write_Buffers (0).Address :=
        Self.Address_Buffer (Self.Address_Buffer'First)'Address;
      Self.Write_Buffers (0).Size    := Self.Address_Buffer'Length;
   end Fill_Address_Buffer;

   ------------------------------
   -- On_Transaction_Completed --
   ------------------------------

   overriding procedure On_Transaction_Completed
     (Self : in out I2C_Device_Driver)
   is
      On_Completed : constant A0B.Callbacks.Callback := Self.On_Completed;

   begin
      --  Cleanup driver's state

      Self.Reset_State;

      --  Notify application

      A0B.Callbacks.Emit (On_Completed);
   end On_Transaction_Completed;

   ---------------------------
   -- On_Transfer_Completed --
   ---------------------------

   overriding procedure On_Transfer_Completed
     (Self : in out I2C_Device_Driver)
   is
      Success : Boolean := True;

   begin
      case Self.State is
         when Initial =>
            raise Program_Error;

         when Write =>
            Self.Transaction.Written_Octets := Self.Write_Buffers (1).Bytes;
            Self.Transaction.State          := Self.Write_Buffers (1).State;

         when Write_Read =>
            Self.Transaction.Written_Octets := Self.Write_Buffers (1).Bytes;
            Self.Transaction.State          := Self.Write_Buffers (1).State;
            Self.State                      := Read;

            Self.Controller.Read
              (Device  => Self'Unchecked_Access,
               Buffers => Self.Read_Buffers,
               Stop    => True,
               Success => Success);

         when Read =>
            Self.Transaction.Read_Octets := Self.Read_Buffers (0).Bytes;
            Self.Transaction.State       := Self.Read_Buffers (0).State;
      end case;
   end On_Transfer_Completed;

   ----------
   -- Read --
   ----------

   procedure Read
     (Self         : in out I2C_Device_Driver'Class;
      Address      : Register_Address;
      Buffer       : out Unsigned_8_Array;
      Status       : aliased out Transaction_Status;
      On_Completed : A0B.Callbacks.Callback;
      Success      : in out Boolean) is
   begin
      if not Success or Self.State /= Initial then
         Success := False;

         return;
      end if;

      Self.Controller.Start (Self'Unchecked_Access, Success);

      if not Success then
         return;
      end if;

      Self.State           := Write_Read;
      Self.On_Completed    := On_Completed;
      Self.Transaction     := Status'Unchecked_Access;
      Self.Transaction.all := (0, 0, Active);

      Self.Fill_Address_Buffer (Address);

      Self.Read_Buffers (0).Address := Buffer (Buffer'First)'Address;
      Self.Read_Buffers (0).Size    := Buffer'Length;

      Self.Controller.Write
        (Device  => Self'Unchecked_Access,
         Buffers => Self.Write_Buffers (0 .. 0),
         Stop    => False,
         Success => Success);

      if not Success then
         Self.Transaction.State := Failure;
         Self.Reset_State;
      end if;
   end Read;

   -----------------
   -- Reset_State --
   -----------------

   procedure Reset_State (Self : in out I2C_Device_Driver'Class) is
   begin
      Self.State          := Initial;
      A0B.Callbacks.Unset (Self.On_Completed);
      Self.Transaction    := null;
      Self.Write_Buffers  := [others => (System.Null_Address, 0, 0, Active)];
      Self.Read_Buffers   := [others => (System.Null_Address, 0, 0, Active)];
   end Reset_State;

   -----------
   -- Write --
   -----------

   procedure Write
     (Self         : in out I2C_Device_Driver'Class;
      Address      : Register_Address;
      Buffer       : Unsigned_8_Array;
      Status       : aliased out Transaction_Status;
      On_Completed : A0B.Callbacks.Callback;
      Success      : in out Boolean) is
   begin
      if not Success or Self.State /= Initial then
         Success := False;

         return;
      end if;

      Self.Controller.Start (Self'Unchecked_Access, Success);

      if not Success then
         return;
      end if;

      Self.State           := Write;
      Self.On_Completed    := On_Completed;
      Self.Transaction     := Status'Unchecked_Access;
      Self.Transaction.all := (0, 0, Active);

      Self.Fill_Address_Buffer (Address);

      Self.Write_Buffers (1).Address := Buffer (Buffer'First)'Address;
      Self.Write_Buffers (1).Size    := Buffer'Length;

      Self.Controller.Write
        (Device  => Self'Unchecked_Access,
         Buffers => Self.Write_Buffers (0 .. 1),
         Stop    => True,
         Success => Success);

      if not Success then
         Self.Transaction.State := Failure;
         Self.Reset_State;
      end if;
   end Write;

end A0B.I2C.Device_Drivers_8;

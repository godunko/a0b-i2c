--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

package body A0B.I2C.Device_Drivers is

   procedure Reset_State (Self : in out I2C_Device_Driver'Class);
   --  Resets state of the driver.

   ------------------------------
   -- On_Transaction_Completed --
   ------------------------------

   overriding procedure On_Transaction_Completed
     (Self : in out I2C_Device_Driver)
   is
      On_Completed : constant A0B.Callbacks.Callback := Self.On_Completed;

   begin
      --  Compute transaction status

      Self.Transaction.all :=
        (Written_Octets => Self.Transfers (0).Status.Bytes,
         Read_Octets    => Self.Transfers (1).Status.Bytes,
         State          =>
           (if Self.Transfers (Self.Current).Status.State = Success
                then Success else Failure));

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
      use type Active_Transfer;

      Success : Boolean := True;

   begin
      if Self.Current = 0
        and then Self.Transfers (Self.Current).Status.State = I2C.Success
        --  and then Self.Transfers (Self.Current).Status.Bytes
        --             = Self.Transfers (Self.Current).Buffer'Length
        and then Self.Transfers (Self.Current + 1).Buffer /= null
      then
         Self.Current := 1;
         Self.Controller.Read
           (Device  => Self'Unchecked_Access,
            Buffer  => Self.Transfers (Self.Current).Buffer.all,
            Status  => Self.Transfers (Self.Current).Status,
            Stop    => True,
            Success => Success);

      else
         declare
            Success : Boolean := True;

         begin
            Self.Controller.Stop
              (Device  => Self'Unchecked_Access,
               Success => Success);
         end;
      end if;
   end On_Transfer_Completed;

   -----------------
   -- Reset_State --
   -----------------

   procedure Reset_State (Self : in out I2C_Device_Driver'Class) is
   begin
      Self.Current := 0;
      Self.Transfers :=
        (others => (Buffer => null, Status => (Bytes => 0, State => Failure)));
      Self.Transaction := null;
      A0B.Callbacks.Unset (Self.On_Completed);
   end Reset_State;

   -----------
   -- Write --
   -----------

   procedure Write
     (Self         : in out I2C_Device_Driver'Class;
      Buffer       : Unsigned_8_Array;
      Status       : aliased out Transaction_Status;
      On_Completed : A0B.Callbacks.Callback;
      Success      : in out Boolean) is
   begin
      Self.Controller.Start (Self'Unchecked_Access, Success);

      if not Success then
         return;
      end if;

      Self.On_Completed   := On_Completed;
      Self.Transaction    := Status'Unchecked_Access;

      Self.Transfers (0) :=
        (Buffer => Buffer'Unrestricted_Access,
         Status => (Bytes => 0, State => Active));
      Self.Transfers (1) :=
        (Buffer => null,
         Status => (Bytes => 0, State => Active));

      Self.Current := 0;
      Self.Controller.Write
        (Device  => Self'Unchecked_Access,
         Buffer  => Buffer,
         Status  => Self.Transfers (Self.Current).Status,
         Stop    => True,
         Success => Success);
   end Write;

   ----------------
   -- Write_Read --
   ----------------

   procedure Write_Read
     (Self         : in out I2C_Device_Driver'Class;
      Write_Buffer : Unsigned_8_Array;
      Read_Buffer  : out Unsigned_8_Array;
      Status       : aliased out Transaction_Status;
      On_Completed : A0B.Callbacks.Callback;
      Success      : in out Boolean) is
   begin
      Self.Controller.Start (Self'Unchecked_Access, Success);

      if not Success then
         return;
      end if;

      Self.On_Completed := On_Completed;
      Self.Transaction  := Status'Unchecked_Access;

      Self.Transfers (0) :=
        (Buffer => Write_Buffer'Unrestricted_Access,
         Status => (Bytes => 0, State => Active));
      Self.Transfers (1) :=
        (Buffer => Read_Buffer'Unrestricted_Access,
         Status => (Bytes => 0, State => Active));

      Self.Current := 0;
      Self.Controller.Write
        (Device  => Self'Unchecked_Access,
         Buffer  => Write_Buffer,
         Status  => Self.Transfers (Self.Current).Status,
         Stop    => False,
         Success => Success);
   end Write_Read;

end A0B.I2C.Device_Drivers;

""" GDM1000 monochromator class unit"""

__version__ = '30.03.2024'
__author__ = 'Serhiy Kobyakov'


import math
from arduino_device import ArduinoDevice


class GDM1000(ArduinoDevice):
    """New Arduino device class template
    """
    # define the device name:
    # this is the string with which the device responds to b'?' query
    _device_name = "GDM1000"

    # other device-specific variables go here:

    def __init__(self, comport):
        """Initialization of GDM1000 monochromator
        """
        # repeat assigning class variables
        # so they are visible in self.__dict__:
        self._device_name = self._device_name

        # Maximum allowed position in stepper motor steps:
        self.__MaxPos = 208307

        # min and max reciprocal centimeters position
        # for the first grating order
        self.__min_pos_cm = 7500.
        self.__max_pos_cm = 17550.

        # convert stepper position to cm-1
        # (17550 - 7500)/208307 = 0.048246098306826
        self.__step_to_cm = 0.048246098306826
        self.__order = 1

        # start serial communication with the device
        # this is the place for the line!
        super().__init__(comport)

    def __del__(self):
        super().__del__()

    # auxiliary calculations
    # ------------------------------------------------------------------
    @staticmethod
    def nm_to_cm(the_nm) -> float:
        """convert wavelength to reciprocal centimeters
        """
        return 1e7 / the_nm

    def get_min_pos_cm(self) -> float:
        """returns the minimal posiible cm-1 position
        according actual order setting
        """
        return self.__order * self.__min_pos_cm

    def pos_to_cm(self, pos) -> float:
        """convert stepper motor position to cm-1
        """
        return self.__order * self.__step_to_cm + \
            self.get_min_pos_cm()

    def cm_to_pos(self, pos_cm) -> int:
        """convert cm-1 to stepper motor position
        """
        return round((pos_cm - self.get_min_pos_cm()) /
                     self.__step_to_cm)

    def nm_to_pos(self, pos_nm) -> int:
        """convert wavelength to stepper motor position
        """
        return round((self.nm_to_cm(pos_nm) -
                      self.get_min_pos_cm()) / self.__step_to_cm)

    def pos_to_nm(self, pos) -> float:
        """convert stepper motor position to wavelength
        """
        return 1e7 / (self.get_min_pos_cm() + pos * self.__step_to_cm)

    def pos_in_range(self, pos) -> bool:
        """check if given stepper motor position is in the allowed range
        """
        if 0 <= int(pos) <= self.__MaxPos:
            return True
        else:
            return False

    # manage settings
    # ------------------------------------------------------------------
    def get_min_pos_nm(self) -> float:
        """get the beginning of the allowed wavelength range
        given the grating order"""
        return math.ceil(self.pos_to_nm(self.__MaxPos)) + 1.

    def get_max_pos_nm(self) -> float:
        """get the end of the allowed wavelength range
        given the grating order"""
        return math.floor(self.pos_to_nm(0)) - 1.

    def get_max_slit_mm(self) -> float:
        """Returns the maximum slit width possible in mm.
        """
        return 3.0

    def set_grating(self, order):
        """Set grating order.
        The term 'grating' is used for unification.
        """
        self.__order = order

    def get_grating(self): -> int
        """Get grating order.
        The term 'grating' is used for unification.
        """
        return self.__order

    def set_pos(self, pos) -> int:
        """Set the device position in stepper motor steps.
        """
        answ = self.send_and_get_answer('s' + str(pos))
        return int(answ)

    def set_pos_cm(self, pos_cm):
        """Set the device position in reciprocal centimeters.
        """
        self.set_pos(self.cm_to_pos(pos_cm))

    def set_pos_nm(self, pos_nm):
        """Set the device position in nanometers.
        """
        self.set_pos(self.nm_to_pos(pos_nm))

    def get_actual_pos(self) -> int:
        """Returns actual device position in stepper motor steps.
        """
        answ = self.send_and_get_answer('p')
        return int(answ)

    def get_actual_pos_cm(self) -> float:
        """Returns actual device position in reciprocal centimeters.
        """
        return round(self.pos_to_cm(self.get_actual_pos()), 4)

    def get_actual_pos_nm(self) -> float:
        """Returns actual device position in nanometers.
        """
        return round(self.pos_to_nm(self.get_actual_pos()), 4)

    # change grating position
    # ------------------------------------------------------------------
    def jump(self):
        """jump one step forward using stepper motor
        useful in backlash adjustment before starting scan.
        """
        self.send_and_get_answer('j')

    def go_to_pos(self, pos):
        """Set the device position in stepper motor steps.
        """
        # ~ print(f"GDM1000: going to pos: {pos} ")
        self.send_and_get_late_answer('g' + str(pos))

    def go_to_pos_cm(self, pos_cm):
        """Set the device position in reciprocal centimeters.
        """
        self.go_to_pos(self.cm_to_pos(pos_cm))

    def go_to_pos_nm(self, pos_nm):
        """Set the device position in nanometers.
        """
        self.go_to_pos(self.nm_to_pos(pos_nm))

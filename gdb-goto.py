import gdb

prev_position = ""
def send_position(filename, line):
    global prev_position
    current_position = "{}:{}".format(filename, line)
    if prev_position == current_position: return
    prev_position = current_position
    print("We're in {}.".format(current_position))

def current_position():
    try:
        frame = gdb.selected_frame()
    except gdb.error:
        return # no frame available
    
    sal = frame.find_sal()
    if not sal: return

    line = sal.line
    if line == 0: return
    
    filename = sal.symtab.fullname()
    
    return filename, line
    
# install prompt hook
def goto_prompt(current_prompt):
    try:
        if not auto_goto.self.value: return
        
        position = current_position()
        if not position: return
        
        send_position(*position)
    finally:
        return current_prompt

# set auto-goto-emacs on|off
class auto_goto(gdb.Parameter):
    self = None
    
    def __init__(self):
        gdb.Parameter.__init__ (self, "auto-goto-emacs", gdb.COMMAND_OBSCURE, gdb.PARAM_BOOLEAN)
        auto_goto.self = self
        self.value = True
        
    def get_set_string(self):
        return "Auto goto emacs is {}.".format("enabled" if self.value else "disabled")

    def get_show_string(self, svalue):
        return self.get_set_string()


class goto_emacs(gdb.Command):
    """\
Open file with emacs. If no argument is provided, try to send the current location. \
Otherwise, send directly the arguments."""
    
    def __init__(self):
        gdb.Command.__init__ (self, "goto-emacs", gdb.COMMAND_OBSCURE)

    def invoke(self, args, from_tty):
        if not args:
            position = current_position()
            if position is None:
                print("Cannot get the current position.")
            else:
                filename, line = position
                print("Goto {}:{}".format(filename, line))
                send_position(filename, line)
        else:
            send_position(args)

def enable_goto_emacs():
    auto_goto()
    gdb.prompt_hook = goto_prompt
    goto_emacs()

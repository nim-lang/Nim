# create a breakpoint on `debugutils.enteringDebugSection`
define enable_enteringDebugSection
	break -function enteringDebugSection
	# run these commands once breakpoint enteringDebugSection is hit
	command
		# enable all breakpoints and watchpoints
		enable
		# continue execution
		cont
	end
end

# create a breakpoint on `debugutils.exitingDebugSection` named exitingDebugSection
define enable_exitingDebugSection
	break -function exitingDebugSection
	# run these commands once breakpoint exitingDebugSection is hit
	command
		# disable all breakpoints and watchpoints
		disable
		# but enable the enteringDebugSection breakpoint
		enable_enteringDebugSection
		# continue execution
		cont
	end
end

# some commands can't be set until the process is running, so set an entry breakpoint
break -function NimMain
# run these commands once breakpoint NimMain is hit
command
	# disable all breakpoints and watchpoints
	disable
	# but enable the enteringDebugSection breakpoint
	enable_enteringDebugSection
	# no longer need this breakpoint
	delete -function NimMain
	# continue execution
	cont
end

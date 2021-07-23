;;; osascript-term --- scripted Terminal command execution using AppleScript -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

(require 'cl-macs)
(require 'simple)
(require 'subr-x)

(defun osa-terminal-exec (cmds &optional delay skip-p)
  "Scripted command execution for the Terminal application.
Useful for avoiding the bottleneck of the Emacs process loop.
For other scenarios, consider delegating to `eshell' or process filters.

Builds a string of AppleScript, feeds it to osascript.
Sends all commands to a single window.
Will reopen if Terminal is closed or not running.
Do not run this command with multiple Terminal windows open.

CMDS is a list of shell commands to be executed.
DELAY is the number of seconds to pause between each \"do script\" invocation.
SKIP-P will generate the script, never evaluating it.

Throws an error if osascript is not found on the variable `exec-path'.
Returns the string representation of the generated script."
  (cl-flet* ((escape-quotes (str) (replace-regexp-in-string "\"" "\\\\\"" str))
             (do-script (str) (format "do script \"%s\"" (escape-quotes str))))
    (with-temp-buffer
      (insert (concat
               "tell application \"Terminal\"\n    reopen\n    activate"
               (cl-loop with n = (length cmds)
                        with delay = (format "delay %g" (or delay 0.01))
                        with nl-indent = "\n    "

                        for cmd being the elements of cmds using (index idx)

                        concat nl-indent

                        if (zerop idx)
                        concat "set shell to "
                        and concat (do-script cmd)
                        and concat " in window 1"
                        and concat nl-indent
                        and concat delay

                        else if (< idx (- n 1))
                        concat (do-script cmd)
                        and concat " in shell"
                        and concat nl-indent
                        and concat delay

                        ;; NOTE: Do not delay after the final command.
                        else concat (do-script cmd)
                        and concat " in shell")
               "\nend tell"))
      (unless skip-p
        (if-let ((osascript-exe (executable-find "osascript")))
            (shell-command-on-region (point-min) (point-max) osascript-exe)
          (error "Unable to locate osascript executable")))
      (buffer-string))))

(provide 'osascript-term)
;;; osascript-term.el ends here

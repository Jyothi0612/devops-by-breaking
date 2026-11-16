# Render with: docker run --rm -v "$PWD:/vhs" ghcr.io/charmbracelet/vhs tools/demo.tape
Output docs/demo.gif

Set FontSize 14
Set Width 960
Set Height 540
Set Padding 16
Set Theme "Catppuccin Mocha"

Type "./dbb start lnx-01"
Enter
Sleep 4s

Type "./dbb exec -- df -h /var/log/app"
Enter
Sleep 2s

Type "./dbb exec -- du -sh /var/log/app"
Enter
Sleep 2s

Type "./dbb exec -- lsof +L1"
Enter
Sleep 2s

Type "./dbb exec -- systemctl reload orders-api"
Enter
Sleep 2s

Type "./dbb check"
Enter
Sleep 4s

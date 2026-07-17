-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor 'Catppuccin Macchiato Dark' 24")
    hl.exec_cmd("kdeconnectd &")
    hl.exec_cmd("zen-browser &")
    hl.exec_cmd("sleep 5 && syncthingtray-qt6 --wait &")
    hl.exec_cmd("mages &")
    hl.exec_cmd("sleep 30 && trayscale --hide-window &")
    hl.exec_cmd("rclone mount SchoolGdrive: /mnt/SchoolGdrive --dir-cache-time 10s --poll-interval 10s --attr-timeout 10s --size-only")
    hl.exec_cmd("rclone mount PersonalGdrive: /mnt/PersonalGdrive --dir-cache-time 10s --poll-interval 10s --attr-timeout 10s --size-only")
    hl.exec_cmd("rclone mount gcrypt: /mnt/gcrypt --dir-cache-time 10s --poll-interval 10s --attr-timeout 10s --size-only")
    hl.exec_cmd("trayscale --hide-window")
end)

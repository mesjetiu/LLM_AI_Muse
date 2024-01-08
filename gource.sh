#!/bin/bash

# todas las opciones en https://github.com/acaudwell/Gource/wiki

# gource -1280x720 --seconds-per-day 10 --key --title "AlgorAI" --background 00ff00 --hide date,dirnames,filenames,progress,usernames --bloom-multiplier 2.0 --bloom-intensity 0.5 --auto-skip-seconds 0.5 --file-idle-time 0 --camera-mode overview -o - | ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -crf 1 -threads 0 -bf 0 gource.mp4

# gource -1280x720 --seconds-per-day 10 --key --title "AlgorAI" --bloom-multiplier 2.0 --bloom-intensity 0.5 --auto-skip-seconds 0.5 --file-idle-time 0 --camera-mode overview -o - | ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -crf 1 -threads 0 -bf 0 gource.mp4


gource -3840x2160 --seconds-per-day 10 --key --title "AlgorAI" --bloom-multiplier 2.0 --bloom-intensity 0.5 --auto-skip-seconds 0.5 --file-idle-time 0 --camera-mode overview -o - | ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -crf 0 -threads 0 -bf 0 gource.mp4




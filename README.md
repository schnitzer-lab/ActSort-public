# ActSort v0.1


ActSort is an active learning accelerated cell sorter tool for calcium imaging, which automates the quality control process of cell extraction. It is a standalone quality control pipeline that can be used to annotate cell candidates extracted by cell extraction algorithms. If you are interested in cell extraction, see [EXTRACT](https://github.com/schnitzer-lab/EXTRACT-public)!


<img src="https://github.com/user-attachments/assets/35ff835c-ca40-44cb-a880-154999f06f67" width=65% align="top" alt="actsort_pipeline">


<img src="https://github.com/user-attachments/assets/f04a8a33-929c-4dee-ad54-963383aeff02" width="28%" align="right" alt="Example_movie"> 

The figure on the right depicts an example cell annotation instance and is taken from our pre-print. The half-hemisphere is imaged through a 7mm x 7mm window with our custom wide-field fluorescence macroscope (1p). Slightly more than 11k cell candidates were found using EXTRACT, and later sorted by human annotators. Green circles represent actual cells, whereas red circles represent cell candidates returned by EXTRACT but rejected by the human annotators.

## Installation
Open MATLAB and click `APPS` then `Install App`. Select `ActSort-public/software/ActSort.mlappinstall`. You can also install the App by double clicking the `ActSort-public/software/ActSort.mlappinstall` under your local path. You can find the App installed in your MATLAB APPS bar! Add to your favoraites by ⭐ it! (We suggest the user to use ActSort-public with **MATLAB 2021b**, as some MATLAB versions have certain required package missing)

## Getting Started
Browse the tutorial video to quickly gain expertise with ActSort. You can view the tutorials :eyes: online to master ActSort step-by-step.


| Tutorial | Watch |
| -------- | ---- |
| 1 - Preprocessing and data upload | [:eyes:](https://youtu.be/xUppZvX0WmY) |
| 2 - Cell sorting | [:eyes:](https://youtu.be/Y9NA7l9GX94) |
| 3 - Saving the final output + loading a model for fine-tuning | [:eyes:](https://youtu.be/Y-u87BXRBRk) |

## Schedule a tutorial session!

Thank you for your interest in ActSort. To receive occasional updates about new releases, to ask questions about ActSort usage, or schedule a tutorial session for your lab, please send an email to extractneurons@gmail.com along with your name and institution. (Please be sure to add this email to your contact list so that replies and announcements do not go to your spam folder).  Thank you!  


## Questions

ActSort code is written and maintained by the current members of Schnitzerlab. If you have any questions or comments, please open an issue or contact via email `extractneurons@gmail.com`.

## Citations
For details of implementation, please see this [paper](https://www.biorxiv.org/content/10.1101/2024.08.21.609011v1.abstract)

Jiang, Y., Akengin, H. O., Zhou, J., Aslihak, M. A., Li, Y., Hernandez, O., ... & Dinc, F., Blanco-Pozo, M., Schnitzer, M. J. (2024). ActSort: An active-learning accelerated cell sorting algorithm for large-scale calcium imaging datasets. bioRxiv, 2024-08.

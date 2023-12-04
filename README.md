# Polynomial Sine Wave Generator

## Introduction
This repository contains a dedicated sine wave generator that employs a polynomial approximation technique. It synthesizes sine waves within a specific range with high precision using a fifth-order polynomial, tailored for fixed-point arithmetic systems.

## Polynomial Approximation
The implemented sine function is approximated by the polynomial `sin(x) = C1x + C2x^2 + C3x^3 + C4x^4 + C5x^5`. The constants used are as follows:

C1 = 3.14065
C2 = 0.20263
C3 = -5.325192
C4 = 0.544677
C5 = 1.8003

![](https://github.com/FelipeFFerreira/MAC-FUC-SEN/blob/master/imgs/simulacao_resultado_parte_3_2.png "")

![](https://github.com/FelipeFFerreira/MAC-FUC-SEN/blob/master/imgs/sen.jpg "")

![](https://github.com/FelipeFFerreira/MAC-FUC-SEN/blob/master/imgs/resultado_simulacao_3_parte_x_0_5.png "")

![](https://github.com/FelipeFFerreira/MAC-FUC-SEN/blob/master/imgs/resultado_simulacao_3_parte_x_0_41.png "")





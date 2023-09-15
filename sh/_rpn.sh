#!/bin/bash

Derivative () {
	to_rpn | derivative $1 | simplify ${N:-20} | to_infix
}


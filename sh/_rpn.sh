#!/bin/bash

Derivative () {
	to_rpn < /dev/stdin | derivative $1 | simplify ${N:-20} | to_infix
}

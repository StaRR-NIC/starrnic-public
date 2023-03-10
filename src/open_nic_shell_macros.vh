// *************************************************************************
//
// Copyright 2020 Xilinx, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *************************************************************************
`ifndef __OPEN_NIC_SHELL_MACROS_VH__
`define __OPEN_NIC_SHELL_MACROS_VH__

`define getbit(width, index, offset)    ((index)*(width) + (offset))
`define getvec(width, index)            ((index)*(width)) +: (width)

`endif

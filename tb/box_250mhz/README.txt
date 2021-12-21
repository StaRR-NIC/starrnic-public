This test has been written with user plugin as stream_switch in mind.
This just checks if the control plane signals from box layer reach the user plugin.

Export simulation for stream switch as top and use the provided compilation do file instead of the generated one.
Since box impl includes headers, Vivado is not automatically able to include the modules instantiated in the headers.
Hence this manual step is there.

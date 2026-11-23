module tb_ecc;
    logic [31:0] data_in;
    logic [38:0] encoded;
    logic [38:0] noisy;
    logic [31:0] data_out;
    logic        sec_err;
    logic        ded_err;

    integer i;
    integer errors = 0;

    ecc_enc enc (
        .data_in(data_in),
        .code_out(encoded)
    );

    ecc_dec dec (
        .code_in(noisy),
        .data_out(data_out),
        .sec_err(sec_err),
        .ded_err(ded_err)
    );

    initial begin
        data_in = 32'h1234_ABCD;
        #1; //let encoder finish before reading encoded

        // no bit flips
        noisy = encoded;
        #1;
        $display("no error : out=%h sec=%b ded=%b", data_out, sec_err, ded_err);
        if (data_out !== data_in || sec_err !== 1'b0 || ded_err !== 1'b0)
            errors = errors + 1;

        // flip every bit one by one (0 to 38)
        for (i = 0; i <= 38; i = i + 1) begin
            noisy = encoded ^ (39'd1 << i);
            #1;
            if (data_out != data_in || !sec_err || ded_err) begin
                $display("1-bit fail at bit %0d: out=%h sec=%b ded=%b", i, data_out, sec_err, ded_err);
                errors = errors + 1;
            end
        end
        $display("1-bit sweep done");

        // flip 2 bits at once
        noisy = encoded ^ (39'd1 << 3) ^ (39'd1 << 17);
        #1;
        $display("2-bit err: out=%h sec=%b ded=%b", data_out, sec_err, ded_err);
        if (sec_err || !ded_err)
            errors = errors + 1;

        if (errors == 0)
            $display("PASS");
        else
            $display("FAIL (%0d errors)", errors);

        $finish;
    end
endmodule
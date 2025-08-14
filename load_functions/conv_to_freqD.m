function b = conv_to_freqD(b, freq_menu)
    disp("Loaded sites: "); disp({b.site});

    if freq_menu == 2
        b(1).fs = 1/60;
    else
        b(1).fs = 1;
    end

    b(1).pad = 10000;

    disp('...converting observatory data to frequency domain');
    ns = length(b);
    disp("Number of magnetic sites: " + ns);

    b(ns).X = []; b(ns).Y = []; b(ns).f = [];
    for i = 1:ns
        [b(i).X, b(i).Y, b(i).f, b(i).fAxis] = ...
            calc_fft(b(i).x, b(i).y, b(1).fs, b(1).pad);
    end
end

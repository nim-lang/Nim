package com.github.nimrod.crosscalculator;

import android.app.Activity;
import android.widget.TextView;
import android.os.Bundle;

public class CrossCalculator extends Activity
{
	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState)
	{
		super.onCreate(savedInstanceState);

		/* Create a TextView and set its content.
		 * the text is retrieved by calling a native
		 * function.
		 */
		TextView  tv = new TextView(this);
		final int a = 4;
		final int b = 18;
		final int c = myAdd(a, b);
		tv.setText("myAdd(" + a + ", " + b + ") = " + c);
		setContentView(tv);
	}

	/* A native method that is implemented by the
	 * 'backend-jni' native library, which is packaged
	 * with this application. Adds to integers.
	 */
	public native int myAdd(int a, int b);

	/* A native method used to initialise Nimrod.
	 */
	static public native void initNimMain();

	/* this is used to load the 'backend-jni' library on application
	 * startup. The library has already been unpacked into
	 * /data/data/com.github.nimrod.backendjni/lib/libbackend-jni.so at
	 * installation time by the package manager.
	 */
	static {
		System.loadLibrary("backend-jni");
		initNimMain();
	}
}

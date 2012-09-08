package com.github.nimrod.crosscalculator;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

public class CrossCalculator extends Activity
{
	private static final String TAG = "CrossCalculator";
	private TextView result_text;
	private EditText edit_text_a, edit_text_b;
	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState)
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.cross_calculator);

		final Button button = (Button)findViewById(R.id.add_button);
		button.setOnClickListener(new View.OnClickListener() {
			public void onClick(View v) { addButtonClicked(); } });

		result_text = (TextView)findViewById(R.id.result_text);
		edit_text_a = (EditText)findViewById(R.id.edit_text_a);
		edit_text_b = (EditText)findViewById(R.id.edit_text_b);
	}

	/** Handles clicks on the addition button.
	 * Reads the values form the input fields and performs the calculation.
	 */
	private void addButtonClicked()
	{
		int a = 0, b = 0;
		String errors = "";
		final String a_text = edit_text_a.getText().toString();
		final String b_text = edit_text_b.getText().toString();
		try {
			a = Integer.valueOf(a_text, 10);
		} catch (NumberFormatException e) {
			errors += "Can't parse a value '" + a_text + "'. ";
		}
		try {
			b = Integer.valueOf(b_text, 10);
		} catch (NumberFormatException e) {
			errors += "Can't parse b value '" + b_text + "'";
		}
		final int c = myAdd(a, b);
		result_text.setText("myAdd(" + a + ", " + b + ") = " + c);

		if (errors.length() > 0) {
			Log.e(TAG, errors);
			Toast.makeText(this, errors, Toast.LENGTH_SHORT).show();
		}
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

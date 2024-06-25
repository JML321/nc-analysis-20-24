# import os
# import csv
# from google.cloud import storage  # Ensure you import the storage module here

# def format_file(input_file, linecount=0):
#     # Generate the output file name based on the input file
#     base_name = os.path.splitext(input_file)[0]
#     output_file_no_quotes = f"{base_name}_noquotes.txt"
#     print(input_file)
#     with open(input_file, 'r', encoding='ISO-8859-1') as infile:
#         header = infile.readline().strip()
        
#         with open(output_file_no_quotes, 'w', encoding='utf-8') as outfile_no_quotes:
#             # Write the header to the output file
#             outfile_no_quotes.write(header + '\n')
#             print("Header written to no quotes file")

#             line_count = 0
#             for line in infile:
#                 line_count += 1
#                 if line_count % 100000 == 0:
#                     print(f"Processed {line_count} lines")
#                 cleaned_line = line.rstrip()
#                 if cleaned_line:
#                     # Remove null characters
#                     cleaned_line = cleaned_line.replace('\x00', '')
#                     # Write to the no quotes file
#                     outfile_no_quotes.write(cleaned_line + '\n')
#                 if line_count > linecount > 0:
#                     break

#     print(f"Formatting complete. File without quotes created: {output_file_no_quotes}")
#     return output_file_no_quotes


# def process_voter_file(input_file):
#     # Create output file name
#     base_name = os.path.splitext(input_file)[0]
#     output_file = f"{base_name}_processed.csv"

#     print(f"Processing file: {input_file}")
#     print(f"Output file will be: {output_file}")

#     with open(input_file, 'r', encoding='ISO-8859-1') as infile, \
#          open(output_file, 'w', newline='', encoding='utf-8') as outfile:
        
#         writer = csv.writer(outfile)

#         # Read the header
#         header = infile.readline().strip()
#         header_fields = header.split('\t')
#         header_fields[0] = "snapshot_dt"
#         writer.writerow(header_fields)
#         print("Header processed and written to CSV")

#         line_count = 0
#         for line in infile:
#             line_count += 1
#             if line_count % 100000 == 0:
#                 print(f"Processed {line_count} lines")

#             # Clean the line (as in format_file)
#             cleaned_line = line.rstrip().replace('\x00', '')
#             if len(cleaned_line) < 2:
#                 continue
#             if cleaned_line:
#                 # Process the line (as in convert_txt_to_csv)
#                 fields = [field.encode('ISO-8859-1').decode('utf-8') for field in cleaned_line.split('\t')]
#                 if fields[0].startswith('\ufeff'):
#                     fields[0] = fields[0][1:]
#                 if len(fields) > 90:
#                     print(f"outlier at line {line_count}")
#                     print(f"outlier size: {len(fields)}")
#                     fields = fields[:90]
                
#                 writer.writerow(fields)

#     print(f"Processing complete. CSV file created: {output_file}")
#     return output_file

# def upload_to_gcs(bucket_name, source_file_name, destination_blob_name):
#     """Uploads a file to the bucket."""
#     storage_client = storage.Client()
#     bucket = storage_client.bucket(bucket_name)
#     blob = bucket.blob(destination_blob_name)

#     blob.upload_from_filename(source_file_name)

#     print(f"File {source_file_name} uploaded to {destination_blob_name}.")


# # Example usage
# if __name__ == "__main__":
#     folder_path = r"C:\Users\justi\Downloads\nc_voterfiles"
#     bucket_name = 'nc-voter-data'  # Replace with your actual bucket name
#     destination_folder = 'nc_voter_files/add-voterfiles'  # Replace with your actual destination folder

#     # print("test")
#     # for filename in os.listdir(folder_path):
#     #     print(filename)
#     #     if filename.endswith('.txt'):
#     #         file_path = os.path.join(folder_path, filename)
#     #         another_txt_file = format_file(file_path)
#     #         output_csv = process_voter_file(another_txt_file)
#     #         print(f"Processed file: {output_csv}")

#     for filename in os.listdir(folder_path):
#         if filename.endswith('.csv'):
#             file_path = os.path.join(folder_path, filename)
#             destination_blob_name = f"{destination_folder}/{filename}"
#             upload_to_gcs(bucket_name, file_path, destination_blob_name)
#             print(f"Uploaded file: {file_path} to bucket: {bucket_name} at {destination_blob_name}")

import tensorflow_probability as tfp
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'  # 0 = all messages are logged (default behavior)
                                          # 1 = INFO messages are not printed
                                          # 2 = INFO and WARNING messages are not printed
                                          # 3 = INFO, WARNING, and ERROR messages are not printed
tfb = tfp.bijectors

# Create a Softplus bijector
softplus_bijector = tfb.Softplus()

# Example input
x = [-1.0, 0.0, 1.0]

# Apply the Softplus bijector
y = softplus_bijector.forward(x)

print("Input:", x)
print("Transformed:", y.numpy())
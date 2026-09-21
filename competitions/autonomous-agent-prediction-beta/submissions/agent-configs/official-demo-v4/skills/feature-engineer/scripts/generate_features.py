#!/usr/bin/env python3
"""Robust CLI script for automated feature generation.

Automatically identifies column types, imputes missing values, and calculates row mean.
"""

import argparse
import os
import sys
import pandas as pd
import numpy as np
from sklearn.impute import SimpleImputer


def main():
    parser = argparse.ArgumentParser(description="Generate automated ML features.")
    parser.add_argument("--train", type=str, default="train.csv", help="Path to train CSV")
    parser.add_argument("--test", type=str, default="test.csv", help="Path to test CSV")
    parser.add_argument("--target", type=str, default="target", help="Target column name")
    args = parser.parse_args()

    print(f"Loading datasets: {args.train}, {args.test}...")
    if not os.path.exists(args.train):
        print(f"Error: Train file '{args.train}' not found.")
        sys.exit(1)
    if not os.path.exists(args.test):
        print(f"Error: Test file '{args.test}' not found.")
        sys.exit(1)

    train_df = pd.read_csv(args.train)
    test_df = pd.read_csv(args.test)

    target_series = None
    if args.target in train_df.columns:
        target_series = train_df[args.target]
        train_df = train_df.drop(columns=[args.target])
    else:
        print(f"Warning: Target column '{args.target}' not found in train_df.")

    # Align columns
    common_cols = [c for c in train_df.columns if c in test_df.columns]
    train_df = train_df[common_cols].copy()
    test_df = test_df[common_cols].copy()

    print(f"Initial shape: train={train_df.shape}, test={test_df.shape}")

    # Identify column types
    num_cols = train_df.select_dtypes(include=[np.number]).columns.tolist()
    cat_cols = train_df.select_dtypes(exclude=[np.number]).columns.tolist()

    # 1. Impute missing values (fit on train, transform test)
    if num_cols:
        print(f"Imputing missing values for {len(num_cols)} numeric columns...")
        num_imputer = SimpleImputer(strategy="median")
        train_df[num_cols] = num_imputer.fit_transform(train_df[num_cols])
        test_df[num_cols] = num_imputer.transform(test_df[num_cols])

    if cat_cols:
        print(f"Imputing missing values for {len(cat_cols)} categorical columns...")
        cat_imputer = SimpleImputer(strategy="most_frequent")
        train_df[cat_cols] = cat_imputer.fit_transform(train_df[cat_cols])
        test_df[cat_cols] = cat_imputer.transform(test_df[cat_cols])

    # 2. Aggregation Features
    if len(num_cols) > 0:
        print("Calculating row-wise mean feature...")
        train_df["row_mean"] = train_df[num_cols].mean(axis=1)
        test_df["row_mean"] = test_df[num_cols].mean(axis=1)

    # Re-attach target
    if target_series is not None:
        train_df[args.target] = target_series

    print(f"Engineered shape: train={train_df.shape}, test={test_df.shape}")
    train_df.to_csv("train_engineered.csv", index=False)
    test_df.to_csv("test_engineered.csv", index=False)
    print("Saved train_engineered.csv and test_engineered.csv successfully.")


if __name__ == "__main__":
    main()